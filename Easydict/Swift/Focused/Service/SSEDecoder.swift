// Copyright © 2026 Easydict contributors. GPL-3.0.

import Foundation

/// Buffers bytes until a complete SSE line exists, including split UTF-8 characters.
struct SSEDecoder {
    private var pending = Data()
    private var dataLines: [String] = []
    private var eventBytes = 0
    private let maximumEventBytes = 1024 * 1024

    mutating func append(_ data: Data) throws -> [String] {
        pending.append(data)
        var events: [String] = []
        while let end = pending.firstIndex(of: 0x0A) {
            var bytes = pending.prefix(upTo: end)
            if bytes.last == 0x0D { bytes = bytes.dropLast() }
            guard let line = String(data: bytes, encoding: .utf8) else { throw LLMError.invalidResponse }
            pending.removeSubrange(...end)
            if let payload = try process(line) { events.append(payload) }
        }
        guard pending.count + eventBytes <= maximumEventBytes else { throw LLMError.responseTooLarge }
        return events
    }

    mutating func finish() throws -> [String] {
        var events: [String] = []
        if !pending.isEmpty {
            guard let line = String(data: pending, encoding: .utf8) else { throw LLMError.invalidResponse }
            pending.removeAll()
            if let event = try process(line.trimmingCharacters(in: .newlines)) { events.append(event) }
        }
        if !dataLines.isEmpty { events.append(dataLines.joined(separator: "\n")) }
        dataLines.removeAll()
        eventBytes = 0
        return events
    }

    private mutating func process(_ line: String) throws -> String? {
        if line.isEmpty {
            defer { dataLines.removeAll(keepingCapacity: true); eventBytes = 0 }
            return dataLines.isEmpty ? nil : dataLines.joined(separator: "\n")
        }
        guard line.hasPrefix("data:") else { return nil }
        let payload = line.dropFirst(5)
        let value = payload.first == " " ? String(payload.dropFirst()) : String(payload)
        eventBytes += value.utf8.count
        guard eventBytes <= maximumEventBytes else { throw LLMError.responseTooLarge }
        dataLines.append(value)
        return nil
    }
}

/// Removes model-emitted think blocks, including tags split between streaming updates.
enum ReasoningFilter {
    static func visibleText(_ text: String, isStreaming: Bool = false) -> String {
        var visible = ""
        var remainder = text[...]
        while let start = remainder.range(of: "<think>") {
            visible += remainder[..<start.lowerBound]
            let after = remainder[start.upperBound...]
            guard let end = after.range(of: "</think>") else { return visible }
            remainder = after[end.upperBound...]
        }
        let opening = "<think>"
        var tail = String(remainder)
        if isStreaming {
            for length in (1 ..< opening.count).reversed() where tail.hasSuffix(String(opening.prefix(length))) {
                tail.removeLast(length)
                break
            }
        }
        return visible + tail
    }
}
