import SwiftUI

/// A secondary action on Home (Audio recall, Flashcards): icon, title and a count.
struct HomeActionTile: View {
    let title: String
    let systemImage: String
    /// The count line, e.g. "148 phrases · hands-free". The count can be highlighted.
    let detail: Text
    let action: () -> Void

    @Environment(\.languageTheme) private var theme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Image(systemName: systemImage)
                    .appTextStyle(.headline)
                    .foregroundStyle(theme.accentText)
                    .frame(width: DS.Size.minTouch, height: DS.Size.minTouch)
                    .background(theme.accentTint, in: .circle)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text(title)
                        .appTextStyle(.tileTitle)
                        .foregroundStyle(DS.Color.ink)
                    detail
                        .appTextStyle(.secondary)
                        .foregroundStyle(DS.Color.inkSecondary)
                }
            }
            .multilineTextAlignment(.leading)
            .padding(DS.Spacing.l)
            .frame(maxWidth: .infinity, minHeight: DS.Size.tileMinHeight, alignment: .topLeading)
            .background(DS.Color.surface, in: .rect(cornerRadius: DS.Radius.tile, style: .continuous))
            .contentShape(.rect(cornerRadius: DS.Radius.tile))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack(spacing: DS.Spacing.l) {
        ForEach(LanguageTheme.all) { theme in
            HStack(spacing: DS.Spacing.s) {
                HomeActionTile(title: "Audio recall", systemImage: "headphones", detail: Text("148 phrases · hands-free")) {}
                HomeActionTile(title: "Flashcards", systemImage: "rectangle.on.rectangle", detail: Text("12 due today")) {}
            }
            .languageTheme(theme)
        }
    }
    .padding(DS.Spacing.screenPadding)
}
