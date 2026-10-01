import SwiftUI

/// The alternative version and the usage note under the word grid.
struct ResultNotes: View {
    let alternative: String?
    let usageNote: String?

    @Environment(\.languageTheme) private var theme

    var body: some View {
        if alternative != nil || usageNote != nil {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                if let alternative {
                    Text("Also: \(Text(alternative).font(NativeTextStyle.inline.customFont(for: theme.script)).foregroundStyle(DS.Color.ink))")
                        .appTextStyle(.secondary)
                        .foregroundStyle(DS.Color.inkSecondary)
                        .typesettingLanguage(theme.script.language)
                }
                if let usageNote {
                    Text(usageNote)
                        .appTextStyle(.secondary)
                        .foregroundStyle(DS.Color.inkSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
