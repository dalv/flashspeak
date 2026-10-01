#if DEBUG
    import SwiftUI

    /// DEBUG only: switch between Free and Pro to test the paywall.
    struct DeveloperSettingsSection: View {
        @Bindable var model: SettingsModel

        var body: some View {
            Section {
                Toggle(isOn: $model.debugForceFree) {
                    SettingsRow("Act as a free user", subtitle: "DEBUG only") { EmptyView() }
                }
            } header: {
                SettingsSectionHeader(title: "Developer")
            }
            .dsListRows()
        }
    }
#endif
