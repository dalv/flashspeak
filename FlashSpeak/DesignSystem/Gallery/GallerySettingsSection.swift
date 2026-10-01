import SwiftUI

/// Settings rows in a native inset-grouped list.
struct GallerySettingsSection: View {
    @State private var autoPlay = true
    @Environment(\.languageTheme) private var theme

    var body: some View {
        Section("Settings rows") {
            NavigationLink(value: "Learning") {
                SettingsRow("Learning") {
                    Text(theme.nativeName)
                        .nativeTextStyle(.segment, script: theme.script)
                }
            }
            NavigationLink(value: "Default speed") {
                SettingsRow("Default speed", value: "Slow")
            }
            Toggle(isOn: $autoPlay) {
                SettingsRow("Auto-play translations")
            }
            SettingsRow("Free plan", subtitle: "2 of 3 translations left today") {
                Button("Upgrade") {}
                    .buttonStyle(.primaryCompact)
            }
            Button("Restore purchases") {}
                .appTextStyle(.callout)
                .foregroundStyle(theme.accentText)
            Button("Delete all my data", role: .destructive) {}
                .appTextStyle(.callout)
                .foregroundStyle(DS.Color.danger)
        }
        .dsListRows()
    }
}
