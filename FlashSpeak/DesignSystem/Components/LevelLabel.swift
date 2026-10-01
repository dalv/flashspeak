import SwiftUI

/// A small capsule label: a proficiency level ("HSK 2", "JLPT N4",
/// "TOPIK 1", "A2") in the language's tint, or a neutral tag ("Casual").
struct LevelLabel: View {
    enum Style: Sendable {
        case level
        case neutral
    }

    enum Size: Sendable {
        case regular
        /// In list rows.
        case compact
    }

    private let text: String
    private let style: Style
    private let size: Size

    @Environment(\.languageTheme) private var theme

    init(_ text: String, style: Style = .level, size: Size = .regular) {
        self.text = text
        self.style = style
        self.size = size
    }

    var body: some View {
        Text(text)
            .appTextStyle(size == .regular ? .sectionLabel : .captionEmphasized)
            .foregroundStyle(style == .level ? theme.accentOnTint : DS.Color.inkSecondary)
            .padding(.horizontal, size == .regular ? DS.Spacing.xs + 2 : DS.Spacing.xs)
            .padding(.vertical, size == .regular ? DS.Spacing.xxs : DS.Spacing.xxs / 2)
            .background(style == .level ? theme.accentTint : DS.Color.ground, in: .capsule)
            .fixedSize()
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack(alignment: .leading, spacing: DS.Spacing.s) {
        ForEach(SampleContent.languages) { language in
            HStack {
                LevelLabel(language.phrases[0].level ?? "")
                LevelLabel("Casual", style: .neutral)
                LevelLabel(language.phrases[0].level ?? "", size: .compact)
            }
            .languageTheme(language.theme)
        }
    }
    .padding(DS.Spacing.screenPadding)
}
