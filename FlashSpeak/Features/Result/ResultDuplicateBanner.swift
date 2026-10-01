import SwiftUI

/// Shown above the card when the phrase is already in the set (exact) or
/// close to one that is (near), with the existing phrase.
struct ResultDuplicateBanner: View {
    let check: DuplicateCheck

    @Environment(\.languageTheme) private var theme

    var body: some View {
        if let existing = check.existing {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Label(title, systemImage: isExact ? "checkmark.circle" : "square.on.square")
                    .appTextStyle(.subheadlineEmphasized)
                    .foregroundStyle(DS.Color.ink)
                Text(detail)
                    .appTextStyle(.secondary)
                    .foregroundStyle(DS.Color.inkSecondary)
                PhraseRow(
                    PhraseContent(
                        english: existing.englishText,
                        native: existing.targetText,
                        reading: existing.reading,
                        romanization: existing.pronunciation.isEmpty ? nil : existing.pronunciation,
                        level: existing.level.map { LevelScale.label(for: $0, languageCode: existing.languageCode) }
                    )
                )
                .padding(DS.Spacing.s)
                .background(DS.Color.surface, in: .rect(cornerRadius: DS.Radius.small, style: .continuous))
            }
            .padding(DS.Spacing.m)
            .background(theme.accentTint, in: .rect(cornerRadius: DS.Radius.list, style: .continuous))
            .accessibilityElement(children: .combine)
        }
    }

    private var isExact: Bool {
        if case .exact = check {
            return true
        }
        return false
    }

    private var title: String {
        isExact ? "Already in your set" : "Similar to a phrase you have"
    }

    private var detail: String {
        isExact
            ? "You've saved this phrase before, so it won't be added twice."
            : "You can still save this one if it's different enough."
    }
}
