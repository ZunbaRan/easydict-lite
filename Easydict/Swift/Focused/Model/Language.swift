// Language names and BCP-47 codes retained from EZLanguageModel.m. GPL-3.0.
import Foundation
import NaturalLanguage

enum Language: String, CaseIterable, Sendable {
    case auto = "auto"
    case simplifiedChinese = "Simplified-Chinese"
    case traditionalChinese = "Traditional-Chinese"
    case classicalChinese = "Classical-Chinese"
    case english = "English"
    case japanese = "Japanese"
    case korean = "Korean"
    case french = "French"
    case spanish = "Spanish"
    case catalan = "Catalan"
    case portuguese = "Portuguese"
    case brazilianPortuguese = "Brazilian-Portuguese"
    case italian = "Italian"
    case german = "German"
    case russian = "Russian"
    case arabic = "Arabic"
    case swedish = "Swedish"
    case romanian = "Romanian"
    case thai = "Thai"
    case slovak = "Slovak"
    case dutch = "Dutch"
    case hungarian = "Hungarian"
    case greek = "Greek"
    case danish = "Danish"
    case finnish = "Finnish"
    case polish = "Polish"
    case czech = "Czech"
    case turkish = "Turkish"
    case lithuanian = "Lithuanian"
    case latvian = "Latvian"
    case ukrainian = "Ukrainian"
    case bulgarian = "Bulgarian"
    case indonesian = "Indonesian"
    case malay = "Malay"
    case slovenian = "Slovenian"
    case estonian = "Estonian"
    case vietnamese = "Vietnamese"
    case persian = "Persian"
    case hindi = "Hindi"
    case telugu = "Telugu"
    case tamil = "Tamil"
    case urdu = "Urdu"
    case filipino = "Filipino"
    case khmer = "Khmer"
    case lao = "Lao"
    case bengali = "Bengali"
    case burmese = "Burmese"
    case norwegian = "Norwegian"
    case serbian = "Serbian"
    case croatian = "Croatian"
    case mongolian = "Mongolian"
    case hebrew = "Hebrew"
    case georgian = "Georgian"
    case uyghur = "Uyghur"

    var code: String {
        switch self {
        case .auto: "und"
        case .simplifiedChinese: "zh-Hans"
        case .traditionalChinese: "zh-Hant"
        case .classicalChinese: "lzh"
        case .english: "en"
        case .japanese: "ja"
        case .korean: "ko"
        case .french: "fr"
        case .spanish: "es"
        case .catalan: "ca"
        case .portuguese: "pt"
        case .brazilianPortuguese: "pt-BR"
        case .italian: "it"
        case .german: "de"
        case .russian: "ru"
        case .arabic: "ar"
        case .swedish: "sv"
        case .romanian: "ro"
        case .thai: "th"
        case .slovak: "sk"
        case .dutch: "nl"
        case .hungarian: "hu"
        case .greek: "el"
        case .danish: "da"
        case .finnish: "fi"
        case .polish: "pl"
        case .czech: "cs"
        case .turkish: "tr"
        case .lithuanian: "lt"
        case .latvian: "lv"
        case .ukrainian: "uk"
        case .bulgarian: "bg"
        case .indonesian: "id"
        case .malay: "ms"
        case .slovenian: "sl"
        case .estonian: "et"
        case .vietnamese: "vi"
        case .persian: "fa"
        case .hindi: "hi"
        case .telugu: "te"
        case .tamil: "ta"
        case .urdu: "ur"
        case .filipino: "fil"
        case .khmer: "km"
        case .lao: "lo"
        case .bengali: "bn"
        case .burmese: "my"
        case .norwegian: "nb"
        case .serbian: "sr-Cyrl"
        case .croatian: "hr"
        case .mongolian: "mn-Mong"
        case .hebrew: "he"
        case .georgian: "ka"
        case .uyghur: "ug"
        }
    }

    var localizedName: String {
        if self == .auto { return AppStrings.text("focused.language.auto") }
        if self == .classicalChinese { return AppStrings.text("focused.language.classical") }
        return Locale.current.localizedString(forIdentifier: code) ?? rawValue
    }

    var isChinese: Bool {
        [.simplifiedChinese, .traditionalChinese, .classicalChinese].contains(self)
    }

    static func detect(_ text: String) -> Language {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(String(text.prefix(6000)))
        guard let code = recognizer.dominantLanguage?.rawValue else { return .auto }
        return allCases.first { $0.code == code } ?? allCases.first { $0.code == code.split(separator: "-").first.map(String.init) } ?? .auto
    }
}

extension Language {
    var queryLanguageName: String {
        let languageName =
            switch self {
            case .classicalChinese:
                "简体中文文言文"
            case .simplifiedChinese:
                "简体中文白话文"
            case .traditionalChinese:
                "繁体中文白话文"
            default:
                rawValue
            }
        return languageName
    }
}
