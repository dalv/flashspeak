import SwiftUI

/// Auto-play, speeds, audio recall options and the better-voices tip.
struct PlaybackSettingsSection: View {
    @Bindable var model: SettingsModel
    let onShowVoices: () -> Void

    var body: some View {
        Section {
            Toggle(isOn: $model.autoPlay) {
                SettingsRow("Auto-play translations") { EmptyView() }
            }
            Picker(selection: $model.defaultSpeed) {
                ForEach(PlaybackSpeed.allCases, id: \.self) { Text($0.title).tag($0) }
            } label: {
                SettingsRow("Default speed") { EmptyView() }
            }
            Picker(selection: $model.recallSpeed) {
                ForEach(PlaybackSpeed.allCases, id: \.self) { Text($0.title).tag($0) }
            } label: {
                SettingsRow("Audio recall speed") { EmptyView() }
            }
            Picker(selection: $model.thinkingGap) {
                ForEach(UserDefaultsSettingsStore.thinkingGaps, id: \.self) { Text("\($0) s").tag($0) }
            } label: {
                SettingsRow("Thinking gap in audio recall") { EmptyView() }
            }
            Toggle(isOn: $model.playTranslationTwice) {
                SettingsRow("Play translations twice", subtitle: "In audio recall") { EmptyView() }
            }
            if !model.hasBetterVoice {
                Button(action: onShowVoices) {
                    SettingsRow("Better voices", subtitle: "Download a more natural \(model.theme.displayName) voice") {
                        Text("How to download")
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            SettingsSectionHeader(title: "Playback")
        }
        .dsListRows()
    }
}
