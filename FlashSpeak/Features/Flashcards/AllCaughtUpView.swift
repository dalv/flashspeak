import SwiftUI

/// Shown when no cards are due: when the next one is, and a way into
/// audio recall.
struct AllCaughtUpView: View {
    let reviewedCount: Int
    let nextDue: Date?
    let canPractise: Bool
    let onAudioRecall: () -> Void

    @Environment(\.languageTheme) private var theme

    var body: some View {
        VStack(spacing: DS.Spacing.l) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: DS.Size.heroMicButton))
                .foregroundStyle(theme.accent)
                .accessibilityHidden(true)

            VStack(spacing: DS.Spacing.xs) {
                Text("All caught up")
                    .appTextStyle(.title)
                    .foregroundStyle(DS.Color.ink)
                Text(detail)
                    .appTextStyle(.body)
                    .foregroundStyle(DS.Color.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()

            if canPractise {
                PrimaryButton("Practise with audio recall", action: onAudioRecall)
            }
        }
        .padding(DS.Spacing.screenPadding)
    }

    private var detail: String {
        let reviewed = reviewedCount == 1 ? "You reviewed 1 card. " : reviewedCount > 1 ? "You reviewed \(reviewedCount) cards. " : ""
        guard let nextDue else {
            return reviewed + "Add more phrases to keep going."
        }
        return reviewed + "Next card due \(nextDue.formatted(.relative(presentation: .named)))."
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    AllCaughtUpView(reviewedCount: 12, nextDue: .now.addingTimeInterval(3 * 3600), canPractise: true, onAudioRecall: {})
        .languageTheme(.mandarin)
}

#Preview("Indonesian", traits: .modifier(DesignSystemPreview())) {
    AllCaughtUpView(reviewedCount: 0, nextDue: .now.addingTimeInterval(86400), canPractise: true, onAudioRecall: {})
        .languageTheme(.indonesian)
}

#Preview("Korean", traits: .modifier(DesignSystemPreview())) {
    AllCaughtUpView(reviewedCount: 1, nextDue: nil, canPractise: false, onAudioRecall: {})
        .languageTheme(.korean)
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    AllCaughtUpView(reviewedCount: 5, nextDue: .now.addingTimeInterval(2 * 86400), canPractise: true, onAudioRecall: {})
        .languageTheme(.japanese)
        .preferredColorScheme(.dark)
}
