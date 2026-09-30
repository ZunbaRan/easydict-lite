// Copyright © 2026 Easydict contributors. GPL-3.0.

import AppKit
import Combine
import Defaults

/// Main-actor request ownership prevents cancelled or superseded responses from changing the panel.
@MainActor
final class LookupController: ObservableObject {
    @Published private(set) var source = ""
    @Published private(set) var result = ""
    @Published private(set) var errorMessage: String?
    @Published private(set) var isRunning = false
    @Published private(set) var mode: LookupMode = .translation
    @Published private(set) var status = ""

    var onShow: ((CGPoint, Bool) -> Void)?
    private var input: LookupInput?
    private var identifier: UUID?
    private let taskControl = OpenAIStreamTaskControl()
    private var accumulated = ""
    private var displayGate = ThrottleGate(interval: 0.05)

    func translateClipboard() {
        // Read exactly once on an explicit menu action. Never clear, restore, or monitor it.
        let text = NSPasteboard.general.string(forType: .string)
        let snapshot = LookupInput(text: text ?? "", anchor: NSEvent.mouseLocation, isClipboard: true)
        start(snapshot, mode: .translation)
    }

    func start(_ input: LookupInput, mode: LookupMode) {
        stop()
        self.input = input
        self.source = input.text
        self.mode = mode
        result = ""
        accumulated = ""
        errorMessage = nil
        status = ""
        onShow?(input.anchor, input.isClipboard)
        guard !input.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = AppStrings.text("focused.error.clipboard_empty")
            return
        }
        // This is an explicit resource limit, not a model-context estimate or silent truncation.
        guard input.text.utf8.count <= 2 * 1024 * 1024 else {
            errorMessage = AppStrings.text("focused.error.input_size")
            return
        }
        let configuration: APIConfiguration
        do { configuration = try .current() } catch { errorMessage = error.localizedDescription; return }
        let first = Language(rawValue: Defaults[.focusedFirstLanguage]) ?? .simplifiedChinese
        let second = Language(rawValue: Defaults[.focusedSecondLanguage]) ?? .english
        let detected = Language.detect(input.text)
        let target = detected == first ? second : first
        let query = ChatQueryParam(text: input.text, sourceLanguage: detected, targetLanguage: target, queryType: mode, enableSystemPrompt: true)
        let customPrompt = Defaults[.focusedCustomPromptEnabled] ? Defaults[.focusedCustomPrompt] : nil
        let messages = PromptBuilder(answerLanguage: first).messages(for: query, customPrompt: customPrompt)
        let current = UUID()
        identifier = current
        taskControl.begin(identifier: current)
        displayGate.reset()
        isRunning = true
        status = AppStrings.text("focused.status.translating")
        let task = Task { [weak self] in
            do {
                try await LLMClient().translate(configuration: configuration, messages: messages) { [weak self] delta in
                    guard let self, self.identifier == current else { return }
                    self.accumulated += delta
                    if self.displayGate.shouldAllow() { self.result = ReasoningFilter.visibleText(self.accumulated, isStreaming: true) }
                }
                guard let self, self.identifier == current, !Task.isCancelled else { return }
                self.result = ReasoningFilter.visibleText(self.accumulated)
                if self.result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { throw LLMError.emptyResponse }
                self.status = AppStrings.text("focused.status.complete")
                self.complete(current)
            } catch {
                guard let self, self.identifier == current else { return }
                self.result = ReasoningFilter.visibleText(self.accumulated)
                if Task.isCancelled || error is CancellationError {
                    self.status = AppStrings.text("focused.status.stopped")
                } else {
                    self.errorMessage = error.localizedDescription
                    self.status = AppStrings.text("focused.status.failed")
                }
                self.complete(current)
            }
        }
        taskControl.install(task, identifier: current)
    }

    func retry(mode: LookupMode? = nil) {
        guard let input else { return }
        start(input, mode: mode ?? self.mode)
    }

    func stop() {
        identifier = nil
        taskControl.cancel()
        if isRunning {
            result = ReasoningFilter.visibleText(accumulated)
            status = AppStrings.text("focused.status.stopped")
        }
        isRunning = false
    }

    func copyResult() {
        guard !result.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
    }

    private func complete(_ current: UUID) {
        taskControl.finish(identifier: current)
        identifier = nil
        isRunning = false
    }
}
