import Foundation

struct Language: Codable, Identifiable, Hashable {
    let code: String
    let name: String
    let flag: String
    let ttsCode: String
    let hasPronunciationGuide: Bool

    var id: String { code }

    static let allLanguages: [Language] = [
        Language(code: "zh-CN", name: "Chinese (Mandarin)", flag: "\u{1F1E8}\u{1F1F3}", ttsCode: "zh-CN", hasPronunciationGuide: true),
        Language(code: "ja", name: "Japanese", flag: "\u{1F1EF}\u{1F1F5}", ttsCode: "ja-JP", hasPronunciationGuide: true),
        Language(code: "ko", name: "Korean", flag: "\u{1F1F0}\u{1F1F7}", ttsCode: "ko-KR", hasPronunciationGuide: true),
        Language(code: "es", name: "Spanish", flag: "\u{1F1EA}\u{1F1F8}", ttsCode: "es-ES", hasPronunciationGuide: false),
        Language(code: "fr", name: "French", flag: "\u{1F1EB}\u{1F1F7}", ttsCode: "fr-FR", hasPronunciationGuide: false),
        Language(code: "de", name: "German", flag: "\u{1F1E9}\u{1F1EA}", ttsCode: "de-DE", hasPronunciationGuide: false),
        Language(code: "it", name: "Italian", flag: "\u{1F1EE}\u{1F1F9}", ttsCode: "it-IT", hasPronunciationGuide: false),
        Language(code: "pt-BR", name: "Portuguese (Brazilian)", flag: "\u{1F1E7}\u{1F1F7}", ttsCode: "pt-BR", hasPronunciationGuide: false),
        Language(code: "ru", name: "Russian", flag: "\u{1F1F7}\u{1F1FA}", ttsCode: "ru-RU", hasPronunciationGuide: true),
        Language(code: "ar", name: "Arabic", flag: "\u{1F1F8}\u{1F1E6}", ttsCode: "ar-SA", hasPronunciationGuide: true),
        Language(code: "hi", name: "Hindi", flag: "\u{1F1EE}\u{1F1F3}", ttsCode: "hi-IN", hasPronunciationGuide: true),
        Language(code: "th", name: "Thai", flag: "\u{1F1F9}\u{1F1ED}", ttsCode: "th-TH", hasPronunciationGuide: true),
        Language(code: "vi", name: "Vietnamese", flag: "\u{1F1FB}\u{1F1F3}", ttsCode: "vi-VN", hasPronunciationGuide: false),
        Language(code: "id", name: "Indonesian", flag: "\u{1F1EE}\u{1F1E9}", ttsCode: "id-ID", hasPronunciationGuide: false),
        Language(code: "tr", name: "Turkish", flag: "\u{1F1F9}\u{1F1F7}", ttsCode: "tr-TR", hasPronunciationGuide: false),
        Language(code: "nl", name: "Dutch", flag: "\u{1F1F3}\u{1F1F1}", ttsCode: "nl-NL", hasPronunciationGuide: false),
        Language(code: "pl", name: "Polish", flag: "\u{1F1F5}\u{1F1F1}", ttsCode: "pl-PL", hasPronunciationGuide: false),
        Language(code: "sv", name: "Swedish", flag: "\u{1F1F8}\u{1F1EA}", ttsCode: "sv-SE", hasPronunciationGuide: false),
        Language(code: "uk", name: "Ukrainian", flag: "\u{1F1FA}\u{1F1E6}", ttsCode: "uk-UA", hasPronunciationGuide: true),
        Language(code: "el", name: "Greek", flag: "\u{1F1EC}\u{1F1F7}", ttsCode: "el-GR", hasPronunciationGuide: true),
    ]

    static func find(byCode code: String) -> Language? {
        allLanguages.first { $0.code == code }
    }

    /// The four languages of the overhaul, in picker order. New code uses
    /// only these; `allLanguages` remains for the legacy views until they go.
    /// Must match `LANGUAGES` in the Worker's `languages.js`.
    static let supportedCodes = ["zh-CN", "id", "ko", "ja"]

    static let supported: [Language] = supportedCodes.compactMap(find(byCode:))

    var isSupported: Bool { Self.supportedCodes.contains(code) }
}
