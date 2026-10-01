// Copyright © 2026 Easydict contributors. GPL-3.0.

import Defaults
import SwiftUI

struct APISettingsView: View {
    @Default(.focusedChannel) private var channel
    @Default(.focusedEndpoint) private var endpoint
    @Default(.focusedModel) private var model
    @Default(.focusedDeepSeekModel) private var deepSeekModel
    @Default(.focusedStreaming) private var streaming
    @Default(.focusedTemperatureEnabled) private var temperatureEnabled
    @Default(.focusedTemperature) private var temperature
    @Default(.focusedThinking) private var thinking
    @State private var apiKey = ""
    @State private var message = ""
    @State private var isTesting = false
    @State private var validationTask: Task<Void, Never>?
    @State private var validationIdentifier: UUID?

    var body: some View {
        Form {
            Section(AppStrings.text("focused.api.connection")) {
                Picker(AppStrings.text("focused.api.channel"), selection: $channel) {
                    ForEach(APIChannel.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                if channel == .compatible {
                    TextField(AppStrings.text("focused.api.endpoint"), text: $endpoint)
                    TextField(AppStrings.text("focused.api.model"), text: $model)
                } else {
                    Text("https://api.deepseek.com/chat/completions").font(.caption).textSelection(.enabled)
                    TextField(AppStrings.text("focused.api.model"), text: $deepSeekModel)
                    Toggle(AppStrings.text("focused.api.thinking"), isOn: $thinking)
                }
                SecureField(AppStrings.text("focused.api.key"), text: $apiKey)
                HStack {
                    Button(AppStrings.text("focused.api.save_key")) { saveKey() }
                    Button(AppStrings.text("focused.api.test")) { testConnection() }.disabled(isTesting)
                    if isTesting {
                        ProgressView().controlSize(.small)
                        Button(AppStrings.text("focused.action.stop")) { cancelValidation() }
                    }
                }
                if !message.isEmpty { Text(message).font(.caption).textSelection(.enabled) }
                Text(AppStrings.text("focused.api.key_note")).font(.caption).foregroundStyle(.secondary)
            }
            Section(AppStrings.text("focused.api.options")) {
                Toggle(AppStrings.text("focused.api.streaming"), isOn: $streaming)
                Toggle(AppStrings.text("focused.api.temperature_enabled"), isOn: $temperatureEnabled)
                if temperatureEnabled {
                    Slider(value: $temperature, in: 0 ... 2, step: 0.1) {
                        Text(String(format: AppStrings.text("focused.api.temperature"), temperature))
                    }
                }
                Text(AppStrings.text("focused.api.compatibility_note")).font(.caption).foregroundStyle(.secondary)
                Text(AppStrings.text("focused.api.thinking_note")).font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear { loadKey() }
        .onChange(of: channel) { _, _ in cancelValidation(); loadKey() }
        .onDisappear { cancelValidation() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in cancelValidation() }
    }

    private func loadKey() {
        do { apiKey = try CredentialStore.read(channel: channel); message = "" }
        catch { apiKey = ""; message = error.localizedDescription }
    }

    @discardableResult
    private func saveKey() -> Bool {
        do {
            try CredentialStore.save(apiKey, channel: channel)
            message = AppStrings.text("focused.api.saved")
            return true
        } catch { message = error.localizedDescription; return false }
    }

    private func cancelValidation() {
        validationIdentifier = nil
        validationTask?.cancel()
        validationTask = nil
        isTesting = false
    }

    private func testConnection() {
        cancelValidation()
        guard saveKey() else { return }
        let configuration: APIConfiguration
        do { configuration = try .current() } catch { message = error.localizedDescription; return }
        let identifier = UUID()
        validationIdentifier = identifier
        isTesting = true
        message = AppStrings.text("focused.api.testing")
        validationTask = Task { @MainActor in
            do {
                try await LLMClient().translate(
                    configuration: configuration,
                    messages: [.init(role: .user, content: "Reply with the word OK.")],
                    allowThinking: false,
                    onText: { _ in }
                )
                guard validationIdentifier == identifier, !Task.isCancelled else { return }
                message = AppStrings.text("focused.api.success")
            } catch {
                guard validationIdentifier == identifier, !Task.isCancelled else { return }
                message = error.localizedDescription
            }
            validationIdentifier = nil
            validationTask = nil
            isTesting = false
        }
    }
}
