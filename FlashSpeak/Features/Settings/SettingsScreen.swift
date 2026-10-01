import SwiftUI

/// Settings: language, review and playback, reminders, Pro and data.
struct SettingsScreen: View {
    @State private var model: SettingsModel
    @State private var showsPaywall = false
    @State private var showsVoices = false

    init(dependencies: AppDependencies) {
        _model = State(initialValue: SettingsModel(dependencies: dependencies))
    }

    var body: some View {
        List {
            LanguageSettingsSection(model: model)
            ReviewSettingsSection(model: model)
            PlaybackSettingsSection(model: model) { showsVoices = true }
            ReminderSettingsSection(model: model)
            ProSettingsSection(model: model) { showsPaywall = true }
            DataSettingsSection(model: model)
            #if DEBUG
                DeveloperSettingsSection(model: model)
            #endif
        }
        .dsGroupedList()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsPaywall) {
            PaywallScreen()
        }
        .sheet(isPresented: $showsVoices) {
            BetterVoicesSheet(languageName: model.theme.displayName)
        }
        .languageTheme(model.theme)
        .onAppear(perform: model.refresh)
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    NavigationStack { SettingsScreen(dependencies: dependencies) }
        .dependencies(dependencies)
}

#Preview("Indonesian, Pro", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview(isPro: true)
    dependencies.settings.currentLanguageCode = "id"
    return NavigationStack { SettingsScreen(dependencies: dependencies) }
        .dependencies(dependencies)
}

#Preview("Korean", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "ko"
    return NavigationStack { SettingsScreen(dependencies: dependencies) }
        .dependencies(dependencies)
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "ja"
    return NavigationStack { SettingsScreen(dependencies: dependencies) }
        .dependencies(dependencies)
        .preferredColorScheme(.dark)
}
