import SwiftUI

/// A settings row: title, optional subtitle, and a trailing value or view.
///
/// Meant for a native inset-grouped `List` with `.dsGroupedList()`.
/// Wrap it in a `NavigationLink` for a chevron, or use a native `Toggle`
/// with a `SettingsRow` label for switches, so both stay native.
struct SettingsRow<Trailing: View>: View {
    private let title: LocalizedStringKey
    private let subtitle: String?
    private let trailing: Trailing

    init(
        _ title: LocalizedStringKey,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: DS.Spacing.s) {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs / 2) {
                Text(title)
                    .appTextStyle(.callout)
                    .foregroundStyle(DS.Color.ink)
                if let subtitle {
                    Text(subtitle)
                        .appTextStyle(.footnote)
                        .foregroundStyle(DS.Color.inkSecondary)
                }
            }
            Spacer(minLength: DS.Spacing.xs)
            trailing
                .appTextStyle(.callout)
                .foregroundStyle(DS.Color.inkSecondary)
        }
        .frame(minHeight: DS.Size.minTouch)
    }
}

extension SettingsRow where Trailing == EmptyView {
    init(_ title: LocalizedStringKey, subtitle: String? = nil) {
        self.init(title, subtitle: subtitle) { EmptyView() }
    }
}

extension SettingsRow where Trailing == Text {
    /// A row with a trailing value, e.g. "Default speed · Slow".
    init(_ title: LocalizedStringKey, subtitle: String? = nil, value: String) {
        self.init(title, subtitle: subtitle) { Text(value) }
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    @Previewable @State var autoPlay = true

    NavigationStack {
        List {
            ForEach(LanguageTheme.all) { theme in
                Section(theme.displayName) {
                    NavigationLink(value: theme.id) {
                        SettingsRow("Learning", value: theme.nativeName)
                    }
                    Toggle(isOn: $autoPlay) {
                        SettingsRow("Auto-play translations")
                    }
                    SettingsRow("Free plan", subtitle: "2 of 3 translations left today") {
                        Button("Upgrade") {}
                            .buttonStyle(.primaryCompact)
                    }
                }
                .dsListRows()
                .languageTheme(theme)
            }
        }
        .dsGroupedList()
    }
}
