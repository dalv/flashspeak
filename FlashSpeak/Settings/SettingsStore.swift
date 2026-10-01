/// App preferences. Observable, so views update when a setting changes.
@MainActor
protocol SettingsStore: AnyObject {
    /// One of `Language.supportedCodes`.
    var currentLanguageCode: String { get set }
    var autoPlay: Bool { get set }
    var defaultSpeed: PlaybackSpeed { get set }
    var hasCompletedOnboarding: Bool { get set }

    // Review
    /// Flashcards show the target language on the front (listening practice).
    var reverseFlashcards: Bool { get set }
    /// Audio recall: seconds between the English and the answer (3, 5 or 8).
    var thinkingGap: Int { get set }
    var recallSpeed: PlaybackSpeed { get set }
    var playTranslationTwice: Bool { get set }
    var recallSessionLength: RecallSessionLength { get set }

    // Reminders
    var reminderEnabled: Bool { get set }
    var reminderTime: ReminderTime { get set }

    func settings(for languageCode: String) -> LanguageSettings
    func update(_ settings: LanguageSettings, for languageCode: String)
}
