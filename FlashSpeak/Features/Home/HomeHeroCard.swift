import SwiftUI

/// The New phrase action: the most prominent thing on Home.
///
/// A pale wash of the language colour with ink text, so it reads as the
/// main action without the alarm of a full accent fill; the solid accent
/// mic button is the one strong accent on the screen.
struct HomeHeroCard: View {
    let action: () -> Void

    @Environment(\.languageTheme) private var theme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("New phrase")
                        .appTextStyle(.display)
                        .foregroundStyle(DS.Color.ink)
                    Text("Say it in English. Hear how a local would say it.")
                        .appTextStyle(.body)
                        .foregroundStyle(DS.Color.inkSecondary)
                }
                Spacer(minLength: DS.Spacing.l)
                HStack(spacing: DS.Spacing.m) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: DS.Size.heroMicButton * 0.4, weight: .semibold))
                        .foregroundStyle(DS.Color.onAccent)
                        .frame(width: DS.Size.heroMicButton, height: DS.Size.heroMicButton)
                        .background(theme.accent, in: .circle)
                        .shadow(.accent(theme.accent))
                        .accessibilityHidden(true)
                    Text("Or type it,\nor get suggestions")
                        .appTextStyle(.subheadline)
                        .foregroundStyle(DS.Color.inkSecondary)
                }
            }
            .multilineTextAlignment(.leading)
            .padding(DS.Spacing.xl)
            .frame(maxWidth: .infinity, minHeight: DS.Size.heroCardMinHeight, alignment: .topLeading)
            .background(theme.accentTint, in: .rect(cornerRadius: DS.Radius.card, style: .continuous))
            .contentShape(.rect(cornerRadius: DS.Radius.card))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("New phrase")
        .accessibilityHint("Say or type a phrase in English to translate it")
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    ScrollView {
        VStack(spacing: DS.Spacing.l) {
            ForEach(LanguageTheme.all) { theme in
                HomeHeroCard {}
                    .languageTheme(theme)
            }
        }
        .padding(DS.Spacing.screenPadding)
    }
}

#Preview("Dark", traits: .modifier(DesignSystemPreview())) {
    VStack(spacing: DS.Spacing.l) {
        ForEach(LanguageTheme.all) { theme in
            HomeHeroCard {}
                .languageTheme(theme)
        }
    }
    .padding(DS.Spacing.screenPadding)
    .preferredColorScheme(.dark)
}
