import SwiftUI

/// The end of a session: phrases practised and time spent.
struct RecallSummaryView: View {
    let practised: Int
    let elapsed: TimeInterval
    let onAgain: () -> Void
    let onDone: () -> Void

    @Environment(\.languageTheme) private var theme

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: DS.Size.heroMicButton))
                .foregroundStyle(theme.accent)
                .accessibilityHidden(true)
            Text("Session complete")
                .appTextStyle(.title)
                .foregroundStyle(DS.Color.ink)
            HStack(spacing: DS.Spacing.s) {
                stat(value: "\(practised)", label: practised == 1 ? "phrase practised" : "phrases practised")
                stat(value: Duration.seconds(elapsed).formatted(.time(pattern: .minuteSecond)), label: "time spent")
            }
            Spacer()
            VStack(spacing: DS.Spacing.s) {
                PrimaryButton("Practise again", action: onAgain)
                Button("Done", action: onDone)
                    .buttonStyle(.secondary)
            }
        }
        .padding(DS.Spacing.screenPadding)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: DS.Spacing.xxs) {
            Text(value)
                .appTextStyle(.display)
                .foregroundStyle(DS.Color.ink)
                .monospacedDigit()
            Text(label)
                .appTextStyle(.secondary)
                .foregroundStyle(DS.Color.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.cardPadding)
        .background(DS.Color.surface, in: .rect(cornerRadius: DS.Radius.tile))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    RecallSummaryView(practised: 20, elapsed: 312, onAgain: {}, onDone: {})
        .languageTheme(.mandarin)
}

#Preview("Indonesian", traits: .modifier(DesignSystemPreview())) {
    RecallSummaryView(practised: 10, elapsed: 151, onAgain: {}, onDone: {})
        .languageTheme(.indonesian)
}

#Preview("Korean", traits: .modifier(DesignSystemPreview())) {
    RecallSummaryView(practised: 1, elapsed: 14, onAgain: {}, onDone: {})
        .languageTheme(.korean)
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    RecallSummaryView(practised: 48, elapsed: 905, onAgain: {}, onDone: {})
        .languageTheme(.japanese)
        .preferredColorScheme(.dark)
}
