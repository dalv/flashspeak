import SwiftUI

/// The accent colours and script of one learning language.
///
/// Components read the current theme from `\.languageTheme`. Set it with
/// `.languageTheme(_:)`, which also tints native controls such as toggles.
/// Keyed by language code so the design system doesn't depend on the
/// `Language` model; the codes match `Language.allLanguages` and the Worker.
struct LanguageTheme: Identifiable, Hashable, Sendable {
    /// The language code, e.g. "zh-CN".
    let id: String
    /// English name, e.g. "Mandarin".
    let displayName: String
    /// Name in the language itself, e.g. "中文". Used in the language picker.
    let nativeName: String
    let script: NativeScript

    /// Filled buttons, play button, selected segment, progress, toggles.
    let accent: Color
    /// Icon wells, small play buttons, level-label and selected-chip backgrounds.
    let accentTint: Color
    /// Text on `accentTint`.
    let accentOnTint: Color
    /// Target-language text and progress in audio recall.
    let accentOnDark: Color
    /// The accent used as text or an icon on `ground` or `surface`
    /// (counts, links). In dark mode this is `accentOnDark` for contrast.
    let accentText: Color

    static func == (lhs: LanguageTheme, rhs: LanguageTheme) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension LanguageTheme {
    static let mandarin = LanguageTheme(
        id: "zh-CN", displayName: "Mandarin", nativeName: "中文", script: .simplifiedChinese,
        accent: 0xC23B22, tint: (0xFBEAE6, 0x422423), onTint: 0xA8321D, onDark: 0xF08A73
    )

    static let indonesian = LanguageTheme(
        id: "id", displayName: "Indonesian", nativeName: "Indonesia", script: .latin,
        accent: 0x0B7A6F, tint: (0xE3F2F0, 0x163335), onTint: 0x0A6A61, onDark: 0x6FD3C6
    )

    static let korean = LanguageTheme(
        id: "ko", displayName: "Korean", nativeName: "한국어", script: .korean,
        accent: 0x2B55C7, tint: (0xE7EDFA, 0x1E2A4A), onTint: 0x254AAD, onDark: 0x8FA9F0
    )

    static let japanese = LanguageTheme(
        id: "ja", displayName: "Japanese", nativeName: "日本語", script: .japanese,
        accent: 0x9B2F6B, tint: (0xF5E6EE, 0x392134), onTint: 0x8A2960, onDark: 0xE08AB8
    )

    /// The four supported languages, in picker order.
    static let all: [LanguageTheme] = [.mandarin, .indonesian, .korean, .japanese]

    /// The theme for a language code, or nil for an unsupported language.
    static func forCode(_ code: String) -> LanguageTheme? {
        all.first { $0.id == code }
    }

    private init(
        id: String, displayName: String, nativeName: String, script: NativeScript,
        accent: UInt32, tint: (light: UInt32, dark: UInt32), onTint: UInt32, onDark: UInt32
    ) {
        self.id = id
        self.displayName = displayName
        self.nativeName = nativeName
        self.script = script
        self.accent = Color(hex: accent)
        accentTint = Color(light: tint.light, dark: tint.dark)
        accentOnTint = Color(light: onTint, dark: onDark)
        accentOnDark = Color(hex: onDark)
        accentText = Color(light: accent, dark: onDark)
    }
}
