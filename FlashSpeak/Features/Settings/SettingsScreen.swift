import SwiftUI

/// Settings: language, review and playback, reminders, Pro and data.
struct SettingsScreen: View {
    @State private var model: SettingsModel
    @State private var showsPaywall = false
    @State private var showsVoices = false
    @State private var confirmsDeleteAll = false
    @Environment(\.openURL) private var openURL

    init(dependencies: AppDependencies) {
        _model = State(initialValue: SettingsModel(dependencies: dependencies))
    }

    var body: some View {
        List {
            languageSection
            reviewSection
            playbackSection
            remindersSection
            proSection
            dataSection
            #if DEBUG
                debugSection
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
        .confirmationDialog("Delete all your data?", isPresented: $confirmsDeleteAll, titleVisibility: .visible) {
            Button("Delete all phrases", role: .destructive) { model.deleteAllData() }
        } message: {
            Text("This deletes every phrase in every language, with its review history. Your subscription isn't affected.")
        }
        .languageTheme(model.theme)
    }

    // MARK: Sections

    private var languageSection: some View {
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
            sectionHeader("Language")
        }
        .dsListRows()
    }

    private var reviewSection: some View {
        Section {
            Picker(selection: levelBinding) {
                Text("Automatic · \(model.levelLabel(model.automaticLevel))").tag(Int?.none)
                ForEach(SetLevel.range, id: \.self) { level in
                    Text(model.levelLabel(level)).tag(Int?.some(level))
                }
            } label: {
                SettingsRow("Your level") { EmptyView() }
            }

            Stepper(value: $model.dailyNewCards, in: 0 ... 50, step: 5) {
                SettingsRow("New cards per day") {
                    Text("\(model.dailyNewCards)").monospacedDigit()
                }
            }

            Toggle(isOn: $model.reverseFlashcards) {
                SettingsRow("Listening-first flashcards", subtitle: "Hear the \(model.theme.displayName) on the front") { EmptyView() }
            }
        } header: {
            sectionHeader("Review")
        }
        .dsListRows()
    }

    private var playbackSection: some View {
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
                Button {
                    showsVoices = true
                } label: {
                    SettingsRow("Better voices", subtitle: "Download a more natural \(model.theme.displayName) voice") {
                        Text("How to download")
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            sectionHeader("Playback")
        }
        .dsListRows()
    }

    private var remindersSection: some View {
        Section {
            Toggle(isOn: reminderBinding) {
                SettingsRow("Daily reminder") { EmptyView() }
            }
            if model.reminderEnabled {
                DatePicker(selection: $model.reminderTime, displayedComponents: .hourAndMinute) {
                    SettingsRow("Time") { EmptyView() }
                }
            }
        } header: {
            sectionHeader("Reminders")
        } footer: {
            if model.reminderDenied {
                Button("Notifications are off for FlashSpeak. Turn them on in Settings.") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                }
                .appTextStyle(.footnote)
                .foregroundStyle(DS.Color.danger)
            }
        }
        .dsListRows()
    }

    private var proSection: some View {
        Section {
            SettingsRow(model.isPro ? "Pro" : "Free plan", subtitle: planDetail) { EmptyView() }
            if !model.isPro {
                Button("Upgrade to Pro") { showsPaywall = true }
                    .appTextStyle(.calloutEmphasized)
                    .foregroundStyle(model.theme.accentText)
            }
            Button {
                Task { await model.restore() }
            } label: {
                SettingsRow("Restore purchases", subtitle: model.restoreMessage) {
                    if model.isRestoring {
                        ProgressView()
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(model.isRestoring)
        } header: {
            sectionHeader("FlashSpeak Pro")
        }
        .dsListRows()
    }

    private var dataSection: some View {
        Section {
            SettingsRow("Sync") { Text(model.syncDescription) }
            ShareLink(item: model.export, preview: SharePreview("FlashSpeak phrases.csv")) {
                SettingsRow("Export my phrases", subtitle: "CSV, opens in Numbers, Excel or Anki") {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .buttonStyle(.plain)
            Button("Delete all my data", role: .destructive) { confirmsDeleteAll = true }
        } header: {
            sectionHeader("Your data")
        }
        .dsListRows()
    }

    #if DEBUG
        private var debugSection: some View {
            Section {
                Toggle(isOn: $model.debugForceFree) {
                    SettingsRow("Act as a free user", subtitle: "DEBUG only") { EmptyView() }
                }
            } header: {
                sectionHeader("Developer")
            }
            .dsListRows()
        }
    #endif

    // MARK: Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .appTextStyle(.sectionLabel)
            .foregroundStyle(DS.Color.inkSecondary)
    }

    private var levelBinding: Binding<Int?> {
        Binding(get: { model.levelOverride }, set: { model.levelOverride = $0 })
    }

    private var reminderBinding: Binding<Bool> {
        Binding(get: { model.reminderEnabled }, set: { enabled in Task { await model.setReminderEnabled(enabled) } })
    }

    private var registerHint: String {
        switch model.register {
        case .casual: "Like a friend would say it"
        case .neutral: "Fine with strangers and staff"
        case .polite: "For elders and formal situations"
        }
    }

    private var planDetail: String? {
        guard !model.isPro, let remaining = model.translationsRemaining else { return nil }
        return "\(remaining) of 3 translations left today"
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
