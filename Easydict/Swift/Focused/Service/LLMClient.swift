// Copyright © 2026 Easydict contributors. GPL-3.0.

import Alamofire
import Foundation

/// Shared Chat Completions transport with request-level thinking controls for known providers.
struct LLMClient {
    private static let maximumResponseBytes = 8 * 1024 * 1024
    private static let session: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 180
        configuration.timeoutIntervalForResource = 900
        configuration.urlCache = nil
        return Session(configuration: configuration)
    }()

    func translate(
        configuration: APIConfiguration,
        messages: [ChatMessage],
        allowThinking: Bool,
        onText: @escaping @MainActor (String) -> Void
    ) async throws {
        try Task.checkCancellation()
        let request = try makeRequest(configuration: configuration, messages: messages, allowThinking: allowThinking)
        // Read both JSON and SSE incrementally so the response-size bound applies before allocation grows.
        // A configured API URL is the destination; never redirect source text or credentials elsewhere.
        let stream = Self.session.streamRequest(request).redirect(using: Redirector(behavior: .doNotFollow))
        defer { stream.cancel() }
        try await withTaskCancellationHandler {
            var decoder = SSEDecoder()
            var fallback = Data()
            var receivedContent = false
            var terminated = false
            var finalReason: String?
            for try await data in boundedData(from: stream) {
                try Task.checkCancellation()
                let response = stream.response
                let isSSE = response?.mimeType?.lowercased() == "text/event-stream"
                if (response?.statusCode).map({ !(200 ... 299).contains($0) }) == true || !isSSE {
                    guard fallback.count + data.count <= Self.maximumResponseBytes else { throw LLMError.responseTooLarge }
                    fallback.append(data)
                    continue
                }
                for payload in try decoder.append(data) {
                    if payload.trimmingCharacters(in: .whitespaces) == "[DONE]" { terminated = true; break }
                    let envelope = try JSONDecoder().decode(ChatEnvelope.self, from: Data(payload.utf8))
                    let (text, finish) = try envelope.content(streaming: true)
                    if !text.isEmpty { receivedContent = true; await onText(text) }
                    if let finish { finalReason = finish }
                }
                if terminated { break }
            }
            try Task.checkCancellation()
            try validate(stream.response, data: fallback)
            if !fallback.isEmpty {
                // Some compatible endpoints ignore stream=true and return a regular JSON completion.
                let envelope = try JSONDecoder().decode(ChatEnvelope.self, from: fallback)
                let (text, finish) = try envelope.content(streaming: false)
                if !text.isEmpty { receivedContent = true; await onText(text) }
                finalReason = finish
                terminated = true
            } else if !terminated {
                for payload in try decoder.finish() {
                    if payload.trimmingCharacters(in: .whitespaces) == "[DONE]" { terminated = true; break }
                    let envelope = try JSONDecoder().decode(ChatEnvelope.self, from: Data(payload.utf8))
                    let (text, finish) = try envelope.content(streaming: true)
                    if !text.isEmpty { receivedContent = true; await onText(text) }
                    if let finish { finalReason = finish }
                }
            }
            guard receivedContent else { throw LLMError.emptyResponse }
            try validateFinish(finalReason)
            guard terminated || finalReason != nil else { throw LLMError.incompleteResponse }
        } onCancel: {
            stream.cancel()
        }
    }

    private func boundedData(from request: DataStreamRequest) -> AsyncThrowingStream<Data, Error> {
        let limit = ResponseByteLimit(maximum: Self.maximumResponseBytes)
        return AsyncThrowingStream { continuation in
            continuation.onTermination = { _ in request.cancel() }
            request.responseStream(on: DispatchQueue(label: "org.easydict.focused.response")) { event in
                switch event.event {
                case let .stream(value):
                    let data = value.get()
                    // Bound the producer as well as decoded output while the UI consumes text.
                    guard limit.accept(data.count) else {
                        continuation.finish(throwing: LLMError.responseTooLarge)
                        request.cancel()
                        return
                    }
                    continuation.yield(data)
                case let .complete(completion):
                    continuation.finish(throwing: completion.error)
                }
            }
        }
    }

    private func makeRequest(configuration: APIConfiguration, messages: [ChatMessage], allowThinking: Bool) throws -> URLRequest {
        let endpoint = configuration.endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var url = URL(string: endpoint), let host = url.host, url.user == nil, url.password == nil,
              url.scheme == "https" || (url.scheme == "http" && ["localhost", "127.0.0.1", "::1", "[::1]"].contains(host))
        else { throw LLMError.invalidEndpoint }
        if url.path.isEmpty || url.path == "/" { url.append(path: "v1/chat/completions") }
        // Compatible base URLs can include a provider prefix, such as /compatible-mode/v1.
        else if url.path.split(separator: "/").last == "v1" { url.append(path: "chat/completions") }
        let model = configuration.model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !model.isEmpty else { throw LLMError.missingModel }
        if configuration.channel == .deepSeek && configuration.apiKey.isEmpty { throw LLMError.missingAPIKey }
        var body: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
            "stream": configuration.streaming,
        ]
        let isDeepSeek = configuration.channel == .deepSeek || host.lowercased() == "api.deepseek.com"
        let thinkingEnabled = allowThinking && configuration.thinking
        if let temperature = configuration.temperature,
           !(isDeepSeek && thinkingEnabled) {
            body["temperature"] = temperature
        }
        if isDeepSeek {
            body["thinking"] = ["type": thinkingEnabled ? "enabled" : "disabled"]
        } else if !allowThinking && isDashScope(host: host) {
            // This is a top-level REST field, not the OpenAI SDK's extra_body wrapper.
            body["enable_thinking"] = false
        }
        var request = URLRequest(url: url, timeoutInterval: 180)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.streaming ? "text/event-stream, application/json" : "application/json", forHTTPHeaderField: "Accept")
        if !configuration.apiKey.isEmpty { request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func isDashScope(host: String) -> Bool {
        let host = host.lowercased()
        return ["dashscope.aliyuncs.com", "dashscope-intl.aliyuncs.com", "dashscope-us.aliyuncs.com"].contains(host)
            || host.hasSuffix(".maas.aliyuncs.com")
    }

    private func validate(_ response: HTTPURLResponse?, data: Data) throws {
        guard let response else { throw LLMError.invalidResponse }
        guard (200 ... 299).contains(response.statusCode) else {
            let message = (try? JSONDecoder().decode(ChatEnvelope.self, from: data))?.error?.message
            throw LLMError.api(status: response.statusCode, message: message ?? HTTPURLResponse.localizedString(forStatusCode: response.statusCode))
        }
    }

    private func validateFinish(_ reason: String?) throws {
        if reason == "length" { throw LLMError.incompleteResponse }
        if let reason, !["stop", "end_turn"].contains(reason) { throw LLMError.unsupportedFinish(reason) }
    }
}

private final class ResponseByteLimit: @unchecked Sendable {
    private let lock = NSLock()
    private let maximum: Int
    private var received = 0

    init(maximum: Int) { self.maximum = maximum }

    func accept(_ count: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        received += count
        return received <= maximum
    }
}

private struct ChatEnvelope: Decodable {
    struct Choice: Decodable {
        struct Content: Decodable { let content: String? }
        let delta: Content?
        let message: Content?
        let finish_reason: String?
    }
    struct APIError: Decodable { let message: String }
    let choices: [Choice]?
    let error: APIError?

    func content(streaming: Bool) throws -> (String, String?) {
        if let error { throw LLMError.api(status: 200, message: error.message) }
        guard let choices else { throw LLMError.invalidResponse }
        guard let choice = choices.first else {
            if streaming { return ("", nil) }
            throw LLMError.emptyResponse
        }
        let text = streaming ? choice.delta?.content ?? "" : choice.message?.content ?? ""
        if !streaming && text.isEmpty { throw LLMError.emptyResponse }
        return (text, choice.finish_reason)
    }
}

enum LLMError: LocalizedError {
    case invalidEndpoint, missingModel, missingAPIKey, invalidResponse, emptyResponse, incompleteResponse, responseTooLarge
    case api(status: Int, message: String)
    case unsupportedFinish(String)

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint: AppStrings.text("focused.error.endpoint")
        case .missingModel: AppStrings.text("focused.error.model")
        case .missingAPIKey: AppStrings.text("focused.error.api_key")
        case .invalidResponse: AppStrings.text("focused.error.response")
        case .emptyResponse: AppStrings.text("focused.error.empty_response")
        case .incompleteResponse: AppStrings.text("focused.error.incomplete")
        case .responseTooLarge: AppStrings.text("focused.error.response_size")
        case let .api(status, message): "HTTP \(status): \(message)"
        case let .unsupportedFinish(reason): AppStrings.text("focused.error.finish") + " (\(reason))"
        }
    }
}
