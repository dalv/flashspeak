import Foundation

/// The writing system of a learning language, which picks its font.
///
/// Chinese and Japanese share Han code points but draw many of them
/// differently, so each script has its own Noto Sans font and Japanese
/// text never falls back to the Chinese font or vice versa.
enum NativeScript: Sendable {
    case simplifiedChinese
    case japanese
    case korean
    /// Indonesian: SF Pro at the native sizes.
    case latin

    /// PostScript name of the bundled font, or nil to use the system font.
    func fontName(bold: Bool) -> String? {
        let family: String
        switch self {
        case .simplifiedChinese: family = "NotoSansSC"
        case .japanese: family = "NotoSansJP"
        case .korean: family = "NotoSansKR"
        case .latin: return nil
        }
        return "\(family)-\(bold ? "Bold" : "Regular")"
    }

    /// Used for line breaking and glyph selection.
    var language: Locale.Language {
        switch self {
        case .simplifiedChinese: Locale.Language(identifier: "zh-Hans")
        case .japanese: Locale.Language(identifier: "ja")
        case .korean: Locale.Language(identifier: "ko")
        case .latin: Locale.Language(identifier: "id")
        }
    }
}
