import SwiftUI

/// The language being learned and how translations sound.
struct LanguageSettingsSection: View {
    @Bindable var model: SettingsModel

    var body: some View {
        Section {
            Picker(selection: $model.languageCode) {
                ForEach(Language.supportedCodes, id: \.self) { code in
                    Text(LanguageTheme.forCode(code)?.displayName ?? code).tag(code)
                }
            } label: {
                SettingsRow("Learning") { EmptyView() }
            }

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                SettingsRow("How translations sound", subtitle: registerHint) { EmptyView() }
                SegmentedControl(selection: $model.register, options: Register.allCases, variant: .inline) {
                    Text($0.title)
                }
            }
            .padding(.vertical, DS.Spacing.xxs)
        } header: {
            SettingsSectionHeader(title: "Language")
        }
        .dsListRows()
    }

    private var registerHint: String {
        switch model.register {
        case .casual: "Like a friend would say it"
        case .neutral: "Fine with strangers and staff"
        case .polite: "For elders and formal situations"
        }
    }
}
