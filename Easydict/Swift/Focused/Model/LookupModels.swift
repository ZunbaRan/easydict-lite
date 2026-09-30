// Copyright © 2026 Easydict contributors. GPL-3.0.

import Defaults
import Foundation

enum LookupMode: String, CaseIterable, Defaults.Serializable {
    case translation
    case dictionary
    case sentence

    var title: String {
        switch self {
        case .translation: AppStrings.text("focused.mode.translation")
        case .dictionary: AppStrings.text("focused.mode.dictionary")
        case .sentence: AppStrings.text("focused.mode.sentence")
        }
    }
}

struct ChatMessage: Codable, Sendable {
    enum ChatRole: String, Codable, Sendable {
        case system, user, assistant
    }

    let role: ChatRole
    let content: String
}

func chatMessagePair(userContent: String, assistantContent: String) -> [ChatMessage] {
    [.init(role: .user, content: userContent), .init(role: .assistant, content: assistantContent)]
}

struct ChatQueryParam {
    let text: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let queryType: LookupMode
    let enableSystemPrompt: Bool

    func unpack() -> (String, Language, Language, LookupMode, Bool) {
        (text, sourceLanguage, targetLanguage, queryType, enableSystemPrompt)
    }
}

/// A lookup owns immutable input; clipboard changes never affect an in-flight request.
struct LookupInput {
    let text: String
    let anchor: CGPoint
    let isClipboard: Bool
}
