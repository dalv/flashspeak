import Foundation
import Observation

/// Settings: language and register, review and playback options,
/// reminders, subscription and data.
@MainActor
@Observable
final class SettingsModel {
    private(set) var reminderDenied = false
    private(set) var restoreMessage: String?
    private(set) var isRestoring = false

    @ObservationIgnored let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    private var settings: any SettingsStore {
        dependencies.settings
    }

    // MARK: Language

    var languageCode: String {
        get { settings.currentLanguageCode }
        set {
            settings.currentLanguageCode = newValue
            Task { await ReminderPlanner(dependencies: dependencies).reschedule() }
        }
    }

    var theme: LanguageTheme {
        LanguageTheme.forCode(languageCode) ?? .mandarin
    }

    var register: Register {
        get { settings.settings(for: languageCode).register }
        set { updateLanguage { $0.register = newValue } }
    }

    /// Nil means automatic (the median of recent phrases).
    var levelOverride: Int? {
        get { settings.settings(for: languageCode).levelOverride }
        set { updateLanguage { $0.levelOverride = newValue } }
    }

    /// The level suggestions use now, from recent phrases or the override.
    var automaticLevel: Int {
        let phrases = (try? dependencies.phrases.phrases(in: languageCode, section: .userPhrases, sort: .newest)) ?? []
        return SetLevel.current(levels: phrases.map(\.level), override: nil)
    }

    func levelLabel(_ level: Int) -> String {
        LevelScale.label(for: level, languageCode: languageCode)
    }

    var dailyNewCards: Int {
        get { settings.settings(for: languageCode).dailyNewCardLimit }
        set { updateLanguage { $0.dailyNewCardLimit = min(max(newValue, 0), 50) } }
    }

    private func updateLanguage(_ change: (inout LanguageSettings) -> Void) {
        var current = settings.settings(for: languageCode)
        change(&current)
        settings.update(current, for: languageCode)
    }

    // MARK: Playback

    var autoPlay: Bool {
        get { settings.autoPlay }
        set { settings.autoPlay = newValue }
    }

    var defaultSpeed: PlaybackSpeed {
        get { settings.defaultSpeed }
        set { settings.defaultSpeed = newValue }
    }

    var recallSpeed: PlaybackSpeed {
        get { settings.recallSpeed }
        set { settings.recallSpeed = newValue }
    }

    var thinkingGap: Int {
        get { settings.thinkingGap }
        set { settings.thinkingGap = newValue }
    }

    var playTranslationTwice: Bool {
        get { settings.playTranslationTwice }
        set { settings.playTranslationTwice = newValue }
    }

    var reverseFlashcards: Bool {
        get { settings.reverseFlashcards }
        set { settings.reverseFlashcards = newValue }
    }

    /// Whether an Enhanced or Premium voice is installed for this language.
    var hasBetterVoice: Bool {
        dependencies.voices.hasHighQualityVoice(for: languageCode)
    }

    // MARK: Reminders

    var reminderEnabled: Bool {
        settings.reminderEnabled
    }

    func setReminderEnabled(_ enabled: Bool) async {
        if enabled {
            guard await dependencies.reminders.requestAuthorization() else {
                reminderDenied = true
                settings.reminderEnabled = false
                return
            }
        }
        reminderDenied = false
        settings.reminderEnabled = enabled
        await ReminderPlanner(dependencies: dependencies).reschedule()
    }

    var reminderTime: Date {
        get { settings.reminderTime.date() }
        set {
            settings.reminderTime = ReminderTime(date: newValue)
            Task { await ReminderPlanner(dependencies: dependencies).reschedule() }
        }
    }

    // MARK: Subscription

    var isPro: Bool {
        dependencies.entitlements.isPro
    }

    var translationsRemaining: Int? {
        dependencies.usage.translationsRemainingToday
    }

    func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await dependencies.entitlements.restore()
            restoreMessage = isPro ? "Pro restored." : "No purchases found for this Apple Account."
        } catch {
            restoreMessage = "Couldn't restore purchases. Try again."
        }
    }

    #if DEBUG
        var debugForceFree: Bool {
            get { dependencies.entitlements.debugForceFree }
            set { dependencies.entitlements.debugForceFree = newValue }
        }
    #endif

    // MARK: Data

    var syncDescription: String {
        switch PersistenceMode.current {
        case .local: "On this iPhone"
        case .cloudKit: "iCloud"
        }
    }

    /// Every phrase in the supported languages, for export.
    func allPhrases() -> [Phrase] {
        Language.supportedCodes.flatMap { code in
            (try? dependencies.phrases.phrases(in: code, section: .all, sort: .oldest)) ?? []
        }
    }

    var export: PhraseExport {
        PhraseExport { [self] in CSVExporter.data(for: allPhrases()) }
    }

    /// Soft-deletes every phrase in every language.
    func deleteAllData(now: Date = .now) {
        for phrase in allPhrases() {
            try? dependencies.phrases.softDelete(phrase, at: now)
        }
        dependencies.reminders.cancel()
        settings.reminderEnabled = false
    }
}
