import SwiftUI

/// Type styles for target-language text in its own script.
///
/// Set in Noto Sans SC / JP / KR, or SF Pro for Indonesian, and scaled with
/// Dynamic Type. Apply with `.nativeTextStyle(_:script:)`.
enum NativeTextStyle: CaseIterable, Sendable {
    /// Answer in audio recall.
    case recall
    /// Flashcard back.
    case flashcard
    /// Result card; Manage cards heading.
    case hero
    /// Word tiles.
    case tile
    /// Suggested-phrase rows.
    case row
    /// Language picker labels.
    case segment
    /// Native text inside list rows and hints.
    case inline
    /// Kana reading line under Japanese.
    case reading

    var size: CGFloat {
        switch self {
        case .recall: 42
        case .flashcard: 38
        case .hero: 34
        case .tile: 20
        case .row: 18
        case .segment, .reading: 15
        case .inline: 14
        }
    }

    var isBold: Bool {
        switch self {
        case .recall, .flashcard, .hero, .tile, .row, .segment: true
        case .inline, .reading: false
        }
    }

    var relativeTo: Font.TextStyle {
        switch self {
        case .recall, .flashcard, .hero: .largeTitle
        case .tile: .title3
        case .row: .headline
        case .segment, .inline, .reading: .subheadline
        }
    }

    /// The bundled font for this style in a script, scaled with Dynamic
    /// Type, or nil for Latin script (which uses SF via the modifier).
    func customFont(for script: NativeScript) -> Font? {
        script.fontName(bold: isBold).map { .custom($0, size: size, relativeTo: relativeTo) }
    }

    /// Name shown in the component gallery.
    var name: String {
        String(describing: self)
    }
}
