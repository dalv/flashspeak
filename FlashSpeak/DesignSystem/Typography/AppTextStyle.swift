import SwiftUI

/// UI and English type styles, set in SF Pro.
///
/// Each style has a design size from the mockups and scales with Dynamic
/// Type relative to a system text style. Apply with `.appTextStyle(_:)`.
enum AppTextStyle: CaseIterable, Sendable {
    case largeTitle
    case title
    /// Home hero title, flashcard English prompt.
    case display
    /// Live transcript while listening.
    case transcript
    /// English prompt in audio recall.
    case recallPrompt
    case tileTitle
    case headline
    case body
    case callout
    case calloutEmphasized
    case subheadline
    case subheadlineEmphasized
    /// Tile subtitles, hints, speed segments.
    case secondary
    case secondaryEmphasized
    case sectionLabel
    /// Uppercase "ENGLISH" label above a prompt.
    case eyebrow
    case footnote
    case caption
    case captionEmphasized
    /// Romanization under the hero phrase.
    case romanization

    var size: CGFloat {
        switch self {
        case .recallPrompt: 36
        case .largeTitle: 34
        case .display, .transcript: 30
        case .title: 28
        case .romanization: 19
        case .tileTitle: 18
        case .headline, .body: 17
        case .callout, .calloutEmphasized: 16
        case .subheadline, .subheadlineEmphasized: 15
        case .secondary, .secondaryEmphasized: 14
        case .sectionLabel, .eyebrow, .footnote: 13
        case .caption, .captionEmphasized: 12
        }
    }

    var weight: Font.Weight {
        switch self {
        case .largeTitle, .title, .display, .recallPrompt, .tileTitle, .headline,
             .subheadlineEmphasized, .secondaryEmphasized, .sectionLabel, .eyebrow, .captionEmphasized:
            .bold
        case .transcript, .calloutEmphasized:
            .semibold
        case .body, .callout, .subheadline, .secondary, .footnote, .caption, .romanization:
            .regular
        }
    }

    var relativeTo: Font.TextStyle {
        switch self {
        case .largeTitle, .recallPrompt: .largeTitle
        case .title, .display, .transcript: .title
        case .romanization: .title3
        case .tileTitle, .headline: .headline
        case .body: .body
        case .callout, .calloutEmphasized: .callout
        case .subheadline, .subheadlineEmphasized, .secondary, .secondaryEmphasized: .subheadline
        case .sectionLabel, .eyebrow, .footnote: .footnote
        case .caption, .captionEmphasized: .caption
        }
    }

    var tracking: CGFloat {
        switch self {
        case .largeTitle: -0.5
        case .recallPrompt: -0.4
        case .title, .display, .transcript: -0.3
        case .eyebrow: 1
        default: 0
        }
    }

    var isUppercase: Bool {
        self == .eyebrow
    }

    /// Name shown in the component gallery.
    var name: String {
        String(describing: self)
    }
}
