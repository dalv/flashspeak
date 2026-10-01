import SwiftUI

/// Before a session: how many phrases to play, then Start.
struct RecallSetupView: View {
    @Binding var length: RecallSessionLength
    let setCount: Int
    let sectionTitle: String
    let speed: PlaybackSpeed
    let onStart: () -> Void

    @Environment(\.languageTheme) private var theme

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()
            Image(systemName: "headphones")
                .font(.system(size: DS.Size.heroMicButton * 0.6, weight: .semibold))
                .foregroundStyle(theme.accentText)
                .frame(width: DS.Size.heroMicButton * 1.3, height: DS.Size.heroMicButton * 1.3)
                .background(theme.accentTint, in: .circle)
                .accessibilityHidden(true)

            VStack(spacing: DS.Spacing.xs) {
                Text("Hands-free practice")
                    .appTextStyle(.title)
                    .foregroundStyle(DS.Color.ink)
                Text("Hear the English, say it out loud, then hear the \(theme.displayName). Works with the screen locked.")
                    .appTextStyle(.body)
                    .foregroundStyle(DS.Color.inkSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: DS.Spacing.s) {
                Text("Phrases this session")
                    .appTextStyle(.sectionLabel)
                    .foregroundStyle(DS.Color.inkSecondary)
                SegmentedControl(selection: $length, options: RecallSessionLength.allCases, variant: .inline) { option in
                    Text(option.title)
                }
                Text("\(sectionTitle) · \(setCount) in set · \(speed.title.lowercased()) speed")
                    .appTextStyle(.footnote)
                    .foregroundStyle(DS.Color.inkSecondary)
            }
            Spacer()

            PrimaryButton("Start", action: onStart)
                .disabled(setCount == 0)
        }
        .padding(DS.Spacing.screenPadding)
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    @Previewable @State var length = RecallSessionLength.twenty
    RecallSetupView(length: $length, setCount: 148, sectionTitle: "All phrases", speed: .slow, onStart: {})
        .languageTheme(.mandarin)
}

#Preview("Indonesian", traits: .modifier(DesignSystemPreview())) {
    @Previewable @State var length = RecallSessionLength.ten
    RecallSetupView(length: $length, setCount: 32, sectionTitle: "User phrases", speed: .slow, onStart: {})
        .languageTheme(.indonesian)
}

#Preview("Korean", traits: .modifier(DesignSystemPreview())) {
    @Previewable @State var length = RecallSessionLength.all
    RecallSetupView(length: $length, setCount: 63, sectionTitle: "Numbers", speed: .natural, onStart: {})
        .languageTheme(.korean)
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    @Previewable @State var length = RecallSessionLength.twenty
    RecallSetupView(length: $length, setCount: 0, sectionTitle: "All phrases", speed: .slow, onStart: {})
        .languageTheme(.japanese)
        .preferredColorScheme(.dark)
}
