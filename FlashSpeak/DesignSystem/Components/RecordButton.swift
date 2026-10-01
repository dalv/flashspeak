import SwiftUI

/// The big round record button: a microphone when idle, a stop square while
/// recording, with a soft halo in the accent.
///
/// Supports tap to start / tap to stop, and hold to talk: `onPressChanged`
/// reports touch down and release, and the owner decides which it was.
/// VoiceOver activates it like a button.
struct RecordButton: View {
    private let isRecording: Bool
    private let onPressChanged: (Bool) -> Void
    private let onAccessibilityActivate: () -> Void

    @Environment(\.languageTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    init(isRecording: Bool, onPressChanged: @escaping (Bool) -> Void, onAccessibilityActivate: @escaping () -> Void) {
        self.isRecording = isRecording
        self.onPressChanged = onPressChanged
        self.onAccessibilityActivate = onAccessibilityActivate
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.accent.opacity(isRecording ? 0.14 : 0))
                .frame(width: DS.Size.recordHalo, height: DS.Size.recordHalo)
            Circle()
                .fill(theme.accent)
                .frame(width: DS.Size.recordButton, height: DS.Size.recordButton)
                .shadow(.accent(theme.accent))
            if isRecording {
                RoundedRectangle(cornerRadius: DS.Spacing.xs - 2, style: .continuous)
                    .fill(DS.Color.onAccent)
                    .frame(width: DS.Size.recordStopGlyph, height: DS.Size.recordStopGlyph)
            } else {
                Image(systemName: "mic.fill")
                    .font(.system(size: DS.Size.recordButton * 0.36, weight: .semibold))
                    .foregroundStyle(DS.Color.onAccent)
            }
        }
        .frame(width: DS.Size.recordHalo, height: DS.Size.recordHalo)
        .opacity(isEnabled ? 1 : DS.Size.disabledOpacity)
        .contentShape(.circle)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: DS.Size.recordHalo) {} onPressingChanged: { pressing in
            onPressChanged(pressing)
        }
        .accessibilityElement()
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onAccessibilityActivate() }
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    HStack {
        ForEach(LanguageTheme.all) { theme in
            RecordButton(isRecording: theme == .korean, onPressChanged: { _ in }, onAccessibilityActivate: {})
                .languageTheme(theme)
        }
    }
    .scaleEffect(0.7)
}
