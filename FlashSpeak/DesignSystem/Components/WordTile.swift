import SwiftUI

/// One word of the gloss: native word, romanization and English meaning.
/// Tapping plays the word. Highlighted while that word is speaking.
struct WordTile: View {
    private let target: String
    private let romanization: String?
    private let english: String
    private let isHighlighted: Bool
    private let action: () -> Void

    @Environment(\.languageTheme) private var theme

    init(target: String, romanization: String?, english: String, isHighlighted: Bool = false, action: @escaping () -> Void) {
        self.target = target
        self.romanization = romanization
        self.english = english
        self.isHighlighted = isHighlighted
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.xxs / 2) {
                Text(target)
                    .nativeTextStyle(.tile, script: theme.script)
                    .foregroundStyle(DS.Color.ink)
                if let romanization {
                    Text(romanization)
                        .appTextStyle(.caption)
                        .foregroundStyle(DS.Color.inkSecondary)
                }
                Text(english)
                    .appTextStyle(.caption)
                    .foregroundStyle(DS.Color.ink)
            }
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.vertical, DS.Spacing.xs)
            .padding(.horizontal, DS.Spacing.s)
            .frame(minWidth: DS.Size.wordTileMinWidth, minHeight: DS.Size.minTouch)
            .background(
                isHighlighted ? theme.accentTint : DS.Color.surfaceSunken,
                in: .rect(cornerRadius: DS.Radius.small, style: .continuous)
            )
            .overlay {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                        .strokeBorder(theme.accent, lineWidth: DS.Size.selectedBorderWidth)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Plays this word")
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack(spacing: DS.Spacing.l) {
        ForEach(LanguageTheme.all) { theme in
            HStack(spacing: DS.Spacing.xs) {
                WordTile(target: "你", romanization: "nǐ", english: "you") {}
                WordTile(target: "再", romanization: "zài", english: "again", isHighlighted: true) {}
                WordTile(target: "お会計", romanization: "okaikei", english: "the bill") {}
                WordTile(target: "udah", romanization: nil, english: "already") {}
            }
            .languageTheme(theme)
        }
    }
    .padding(DS.Spacing.screenPadding)
}
