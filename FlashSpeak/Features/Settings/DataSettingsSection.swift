import SwiftUI

/// Sync status, CSV export and deleting everything.
struct DataSettingsSection: View {
    let model: SettingsModel

    @State private var confirmsDeleteAll = false

    var body: some View {
        Section {
            SettingsRow("Sync") { Text(model.syncDescription) }
            ShareLink(item: model.export, preview: SharePreview("FlashSpeak phrases.csv")) {
                SettingsRow("Export my phrases", subtitle: "CSV, opens in Numbers, Excel or Anki") {
                    Image(systemName: "square.and.arrow.up")
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            Button("Delete all my data", role: .destructive) { confirmsDeleteAll = true }
                .confirmationDialog("Delete all your data?", isPresented: $confirmsDeleteAll, titleVisibility: .visible) {
                    Button("Delete all phrases", role: .destructive) { model.deleteAllData() }
                } message: {
                    Text("This deletes every phrase in every language, with its review history. Your subscription isn't affected.")
                }
        } header: {
            SettingsSectionHeader(title: "Your data")
        }
        .dsListRows()
    }
}
