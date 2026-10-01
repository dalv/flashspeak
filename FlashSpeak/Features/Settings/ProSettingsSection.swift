import SwiftUI

/// Current plan, upgrade and restore.
struct ProSettingsSection: View {
    let model: SettingsModel
    let onUpgrade: () -> Void

    var body: some View {
        Section {
            SettingsRow(model.isPro ? "Pro" : "Free plan", subtitle: planDetail) { EmptyView() }
            if !model.isPro {
                Button("Upgrade to Pro", action: onUpgrade)
                    .appTextStyle(.calloutEmphasized)
                    .foregroundStyle(model.theme.accentText)
            }
            Button(action: restore) {
                SettingsRow("Restore purchases", subtitle: model.restoreMessage) {
                    if model.isRestoring { ProgressView() }
                }
            }
            .buttonStyle(.plain)
            .disabled(model.isRestoring)
        } header: {
            SettingsSectionHeader(title: "FlashSpeak Pro")
        }
        .dsListRows()
    }

    private var planDetail: String? {
        guard !model.isPro, let remaining = model.translationsRemaining else { return nil }
        return "\(remaining) of 3 translations left today"
    }

    private func restore() {
        Task { await model.restore() }
    }
}
