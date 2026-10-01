import SwiftUI

/// A round play button. While playing, the icon becomes an animated
/// waveform (still under Reduce Motion) and the button stops playback.
struct PlayButton: View {
    enum Size: Sendable {
        /// Flashcard back.
        case large
        /// Result card.
        case medium
        /// Suggested-phrase rows.
        case row
        /// Manage-cards rows.
        case compact

        var diameter: CGFloat {
            switch self {
            case .large: DS.Size.playButtonLarge
            case .medium: DS.Size.playButtonMedium
            case .row: DS.Size.playButtonRow
            case .compact: DS.Size.playButtonCompact
            }
        }

        /// Large and medium are filled with the accent; row sizes are tinted.
        var isFilled: Bool {
            self == .large || self == .medium
        }
    }

    private let size: Size
    private let isPlaying: Bool
    private let action: () -> Void

    @Environment(\.languageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(size: Size, isPlaying: Bool = false, action: @escaping () -> Void) {
        self.size = size
        self.isPlaying = isPlaying
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(isPlaying ? "Stop" : "Play", systemImage: isPlaying ? "waveform" : "play.fill")
                .labelStyle(.iconOnly)
                .font(.system(size: size.diameter * 0.38, weight: .semibold))
                .symbolEffect(.variableColor.iterative, isActive: isPlaying && !reduceMotion)
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(size.isFilled ? DS.Color.onAccent : theme.accentText)
                .frame(width: size.diameter, height: size.diameter)
                .background(size.isFilled ? theme.accent : theme.accentTint, in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack(spacing: DS.Spacing.l) {
        ForEach(LanguageTheme.all) { theme in
            HStack(spacing: DS.Spacing.m) {
                PlayButton(size: .large) {}
                PlayButton(size: .medium, isPlaying: true) {}
                PlayButton(size: .row) {}
                PlayButton(size: .compact, isPlaying: true) {}
            }
            .languageTheme(theme)
        }
    }
}
