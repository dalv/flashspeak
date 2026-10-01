import SwiftUI

/// The two flashcard ratings: Hard (FSRS Again) and Easy (FSRS Good).
///
/// Each shows when the card comes back, e.g. "Again soon" or "In 4 days".
/// Easy is the screen's one filled accent button.
struct RatingButtons: View {
    private let hardDetail: String
    private let easyDetail: String
    private let onHard: () -> Void
    private let onEasy: () -> Void

    @Environment(\.languageTheme) private var theme

    init(
        hardDetail: String,
        easyDetail: String,
        onHard: @escaping () -> Void,
        onEasy: @escaping () -> Void
    ) {
        self.hardDetail = hardDetail
        self.easyDetail = easyDetail
        self.onHard = onHard
        self.onEasy = onEasy
    }

    var body: some View {
        HStack(spacing: DS.Spacing.s) {
            Button(action: onHard) {
                RatingLabel(title: "Hard", detail: hardDetail)
                    .foregroundStyle(DS.Color.ink)
                    .background(DS.Color.surface, in: .capsule)
                    .overlay {
                        Capsule().strokeBorder(DS.Color.controlBorder, lineWidth: DS.Size.hairlineWidth)
                    }
            }
            Button(action: onEasy) {
                RatingLabel(title: "Easy", detail: easyDetail)
                    .foregroundStyle(DS.Color.onAccent)
                    .background(theme.accent, in: .capsule)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Title and detail inside a rating button.
private struct RatingLabel: View {
    let title: LocalizedStringKey
    let detail: String

    var body: some View {
        VStack(spacing: DS.Spacing.xxs / 2) {
            Text(title)
                .appTextStyle(.headline)
            Text(detail)
                .appTextStyle(.footnote)
                .opacity(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: DS.Size.ratingButtonHeight)
        .contentShape(.capsule)
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack(spacing: DS.Spacing.s) {
        ForEach(LanguageTheme.all) { theme in
            RatingButtons(hardDetail: "Again soon", easyDetail: "In 4 days", onHard: {}, onEasy: {})
                .languageTheme(theme)
        }
    }
    .padding(DS.Spacing.screenPadding)
}
