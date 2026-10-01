import SwiftUI

/// The daily reminder and its time.
struct ReminderSettingsSection: View {
    @Bindable var model: SettingsModel

    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            Toggle(isOn: $model.wantsReminder) {
                SettingsRow("Daily reminder") { EmptyView() }
            }
            .onChange(of: model.wantsReminder) { _, wants in
                guard wants != model.reminderEnabled else { return }
                Task { await model.setReminderEnabled(wants) }
            }
            if model.reminderEnabled {
                DatePicker(selection: $model.reminderTime, displayedComponents: .hourAndMinute) {
                    SettingsRow("Time") { EmptyView() }
                }
            }
        } header: {
            SettingsSectionHeader(title: "Reminders")
        } footer: {
            if model.reminderDenied {
                Button("Notifications are off for FlashSpeak. Turn them on in Settings.", action: openNotificationSettings)
                    .appTextStyle(.footnote)
                    .foregroundStyle(DS.Color.danger)
            }
        }
        .dsListRows()
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(url)
        }
    }
}
