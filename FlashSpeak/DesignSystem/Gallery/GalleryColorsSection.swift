import SwiftUI

/// Neutral, recall and per-language accent colours.
struct GalleryColorsSection: View {
    private let neutrals: [(String, Color)] = [
        ("ground", DS.Color.ground),
        ("surface", DS.Color.surface),
        ("surfaceSunken", DS.Color.surfaceSunken),
        ("ink", DS.Color.ink),
        ("inkSecondary", DS.Color.inkSecondary),
        ("inkTertiary", DS.Color.inkTertiary),
        ("hairline", DS.Color.hairline),
        ("separator", DS.Color.separator),
        ("controlBorder", DS.Color.controlBorder),
        ("borderStrong", DS.Color.controlBorderStrong),
        ("danger", DS.Color.danger),
        ("recallGround", DS.Color.recallGround),
    ]

    private let columns = [GridItem(.adaptive(minimum: DS.Size.minTouch * 1.6), spacing: DS.Spacing.s)]

    var body: some View {
        Section("Colour") {
            LazyVGrid(columns: columns, alignment: .leading, spacing: DS.Spacing.s) {
                ForEach(neutrals, id: \.0) { name, color in
                    GallerySwatch(name: name, color: color)
                }
            }
            .padding(.vertical, DS.Spacing.xs)

            ForEach(LanguageTheme.all) { theme in
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(theme.displayName)
                        .appTextStyle(.subheadlineEmphasized)
                        .foregroundStyle(DS.Color.ink)
                    HStack(spacing: DS.Spacing.s) {
                        GallerySwatch(name: "accent", color: theme.accent)
                        GallerySwatch(name: "tint", color: theme.accentTint)
                        GallerySwatch(name: "onTint", color: theme.accentOnTint)
                        GallerySwatch(name: "onDark", color: theme.accentOnDark)
                    }
                }
                .padding(.vertical, DS.Spacing.xxs)
            }
        }
        .dsListRows()
    }
}
