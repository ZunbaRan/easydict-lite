// Copyright © 2026 Easydict contributors. GPL-3.0.

import Defaults
import Foundation

enum APIChannel: String, CaseIterable, Defaults.Serializable, Sendable {
    case compatible
    case deepSeek

    var title: String {
        switch self {
        case .compatible: AppStrings.text("focused.api.compatible")
        case .deepSeek: "DeepSeek"
        }
    }
}

extension Defaults.Keys {
    static let focusedChannel = Key<APIChannel>("focused.channel", default: .compatible)
    static let focusedEndpoint = Key<String>("focused.endpoint", default: "https://api.openai.com/v1/chat/completions")
    static let focusedModel = Key<String>("focused.model", default: "")
    static let focusedDeepSeekModel = Key<String>("focused.deepseek.model", default: "deepseek-flash")
    static let focusedStreaming = Key<Bool>("focused.streaming", default: true)
    static let focusedTemperatureEnabled = Key<Bool>("focused.temperature.enabled", default: false)
    static let focusedTemperature = Key<Double>("focused.temperature", default: 0.3)
    static let focusedThinking = Key<Bool>("focused.thinking", default: false)
    static let focusedFirstLanguage = Key<String>("focused.language.first", default: "Simplified-Chinese")
    static let focusedSecondLanguage = Key<String>("focused.language.second", default: "English")
    static let focusedSelectionEnabled = Key<Bool>("focused.selection.enabled", default: true)
    static let focusedExcludedLanguage = Key<String>("focused.selection.excluded", default: "Simplified-Chinese")
    static let focusedMinimumLength = Key<Int>("focused.selection.minimum_length", default: 1)
    static let focusedSelectionMode = Key<LookupMode>("focused.selection.mode", default: .dictionary)
    static let focusedCustomPrompt = Key<String>("focused.prompt.custom", default: "")
    static let focusedCustomPromptEnabled = Key<Bool>("focused.prompt.enabled", default: false)
    static let focusedPinned = Key<Bool>("focused.window.pinned", default: false)
    static let focusedMaximumHeight = Key<Double>("focused.window.maximum_height", default: 0.7)
    static let focusedAllSpaces = Key<Bool>("focused.window.all_spaces", default: true)
    static let focusedRememberPosition = Key<Bool>("focused.window.remember_position", default: false)
}

/// Snapshot preferences so changes in Settings affect only the next request.
struct APIConfiguration: Sendable {
    let channel: APIChannel
    let endpoint: String
    let model: String
    let apiKey: String
    let streaming: Bool
    let temperature: Double?
    let thinking: Bool

    @MainActor
    static func current() throws -> APIConfiguration {
        let channel = Defaults[.focusedChannel]
        return APIConfiguration(
            channel: channel,
            endpoint: channel == .deepSeek ? "https://api.deepseek.com/chat/completions" : Defaults[.focusedEndpoint],
            model: channel == .deepSeek ? Defaults[.focusedDeepSeekModel] : Defaults[.focusedModel],
            apiKey: try CredentialStore.read(channel: channel),
            streaming: Defaults[.focusedStreaming],
            temperature: Defaults[.focusedTemperatureEnabled] ? Defaults[.focusedTemperature] : nil,
            thinking: Defaults[.focusedThinking]
        )
    }
}
