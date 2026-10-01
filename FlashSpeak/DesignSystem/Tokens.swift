import SwiftUI

/// The design tokens: colour, spacing, shape, sizes and elevation.
///
/// This is the single token file the PRD asks for. Views never use raw
/// colours, sizes or spacing; they use these. Values and their rationale
/// are documented in `dev-docs/design-system.md`. Per-language accents are
/// in `LanguageTheme`, type styles in `AppTextStyle` and `NativeTextStyle`.
enum DS {
    /// Neutral and recall colours. Neutrals adapt to dark mode; recall
    /// colours are fixed because audio recall is always dark.
    enum Color {
        static let ground = SwiftUI.Color(light: 0xF2F3F5, dark: 0x0E1014)
        static let surface = SwiftUI.Color(light: 0xFFFFFF, dark: 0x1A1D23)
        static let surfaceSunken = SwiftUI.Color(light: 0xF7F8FA, dark: 0x22262D)

        static let ink = SwiftUI.Color(light: 0x15171C, dark: 0xF3F4F6)
        static let inkSecondary = SwiftUI.Color(light: 0x5B616E, dark: 0x9AA1AD)
        /// Decorative only (unconfirmed transcript words). Below 4.5:1.
        static let inkTertiary = SwiftUI.Color(light: 0x9AA0AB, dark: 0x6B717C)
        /// Text and icons on an accent or danger fill.
        static let onAccent = SwiftUI.Color(light: 0xFFFFFF, dark: 0xFFFFFF)

        static let hairline = SwiftUI.Color(light: 0xE3E5EA, dark: 0x2C3038)
        static let separator = SwiftUI.Color(light: 0xEDEFF2, dark: 0x252930)
        static let controlBorder = SwiftUI.Color(light: 0xD5D8DE, dark: 0x3A3F48)
        static let controlBorderStrong = SwiftUI.Color(light: 0xB8BDC7, dark: 0x555B66)

        /// Destructive text and icons.
        static let danger = SwiftUI.Color(light: 0xB42318, dark: 0xF97066)
        /// Fill behind white text on destructive actions (swipe to delete).
        static let dangerFill = SwiftUI.Color(light: 0xB42318, dark: 0xD92D20)

        static let recallGround = SwiftUI.Color(hex: 0x0E1014)
        static let recallInk = SwiftUI.Color(hex: 0xF3F4F6)
        static let recallInkSecondary = SwiftUI.Color(hex: 0x9AA1AD)
        static let recallTrack = SwiftUI.Color.white.opacity(0.12)

        /// Shadow colour for the flashcard and segment thumbs.
        static let shadow = SwiftUI.Color.black
    }

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32

        static let screenPadding: CGFloat = 20
        static let recallScreenPadding: CGFloat = 24
        static let cardPadding: CGFloat = 20
        static let flashcardPadding: CGFloat = 28
        static let rowPaddingHorizontal: CGFloat = 14
        static let rowPaddingVertical: CGFloat = 12
    }

    enum Radius {
        static let cardLarge: CGFloat = 32
        static let card: CGFloat = 28
        static let tile: CGFloat = 24
        static let list: CGFloat = 20
        static let field: CGFloat = 14
        static let small: CGFloat = 12
    }

    enum Size {
        static let minTouch: CGFloat = 44
        static let primaryButtonHeight: CGFloat = 54
        static let compactButtonHeight: CGFloat = 36
        static let ratingButtonHeight: CGFloat = 64
        static let segmentHeight: CGFloat = 40
        static let inlineSegmentHeight: CGFloat = 36

        static let playButtonLarge: CGFloat = 56
        static let playButtonMedium: CGFloat = 52
        static let playButtonRow: CGFloat = 40
        static let playButtonCompact: CGFloat = 36

        static let recordButton: CGFloat = 88
        static let recordHalo: CGFloat = 124
        static let recordStopGlyph: CGFloat = 26

        /// Home: the New phrase hero card and the two action tiles.
        static let heroCardMinHeight: CGFloat = 260
        static let heroMicButton: CGFloat = 76
        static let tileMinHeight: CGFloat = 150

        static let waveformBarWidth: CGFloat = 4
        static let waveformHeight: CGFloat = 48
        static let waveformBars = 21

        /// Minimum width of a word tile in a grid.
        static let wordTileMinWidth: CGFloat = 72
        static let progressBarHeight: CGFloat = 4
        static let hairlineWidth: CGFloat = 1
        static let selectedBorderWidth: CGFloat = 2

        /// Opacity of a disabled filled control.
        static let disabledOpacity: Double = 0.4
        /// Opacity of a filled control while pressed.
        static let pressedOpacity: Double = 0.85
    }

    struct Shadow {
        let color: SwiftUI.Color
        let radius: CGFloat
        let y: CGFloat

        /// Flashcard only.
        static let card = Shadow(color: Color.shadow.opacity(0.06), radius: 30, y: 10)
        /// Selected thumb of a segmented control.
        static let thumb = Shadow(color: Color.shadow.opacity(0.12), radius: 3, y: 1)

        /// Home hero card and record button, in the language's accent.
        static func accent(_ accent: SwiftUI.Color) -> Shadow {
            Shadow(color: accent.opacity(0.3), radius: 30, y: 10)
        }
    }
}

extension View {
    func shadow(_ shadow: DS.Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius / 2, y: shadow.y)
    }
}
