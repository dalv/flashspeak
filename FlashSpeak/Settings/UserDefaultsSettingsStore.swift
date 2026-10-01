import Foundation
import Observation

/// `SettingsStore` on `UserDefaults`. Reuses the 1.x keys where they exist
/// (`currentLanguageCode`, `autoPlayAudio`, `formality`) so choices carry
/// over. Previews and tests pass their own `UserDefaults` suite.
@MainActor
@Observable
final class UserDefaultsSettingsStore: SettingsStore {
    @ObservationIgnored private let defaults: UserDefaults

    var currentLanguageCode: String {
        didSet { defaults.set(currentLanguageCode, forKey: Keys.currentLanguage) }
    }

    var autoPlay: Bool {
        didSet { defaults.set(autoPlay, forKey: Keys.autoPlay) }
    }

    var defaultSpeed: PlaybackSpeed {
        didSet { defaults.set(defaultSpeed.rawValue, forKey: Keys.defaultSpeed) }
    }

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.onboarding) }
    }

    var reverseFlashcards: Bool {
        didSet { defaults.set(reverseFlashcards, forKey: Keys.reverseFlashcards) }
    }

    var thinkingGap: Int {
        didSet { defaults.set(thinkingGap, forKey: Keys.thinkingGap) }
    }

    var recallSpeed: PlaybackSpeed {
        didSet { defaults.set(recallSpeed.rawValue, forKey: Keys.recallSpeed) }
    }

    var playTranslationTwice: Bool {
        didSet { defaults.set(playTranslationTwice, forKey: Keys.playTwice) }
    }

    var recallSessionLength: RecallSessionLength {
        didSet { defaults.set(recallSessionLength.rawValue, forKey: Keys.recallLength) }
    }

    var hasSeenRecallHint: Bool {
        didSet { defaults.set(hasSeenRecallHint, forKey: Keys.recallHint) }
    }

    var reminderEnabled: Bool {
        didSet { defaults.set(reminderEnabled, forKey: Keys.reminderEnabled) }
    }

    var reminderTime: ReminderTime {
        didSet {
            if let data = try? JSONEncoder().encode(reminderTime) {
                defaults.set(data, forKey: Keys.reminderTime)
            }
        }
    }

    private var perLanguage: [String: LanguageSettings] {
        didSet {
            if let data = try? JSONEncoder().encode(perLanguage) {
                defaults.set(data, forKey: Keys.perLanguage)
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedLanguage = defaults.string(forKey: Keys.currentLanguage) ?? ""
        currentLanguageCode = Language.supportedCodes.contains(storedLanguage)
            ? storedLanguage
            : Language.supportedCodes[0]
        autoPlay = defaults.object(forKey: Keys.autoPlay) as? Bool ?? true
        defaultSpeed = defaults.string(forKey: Keys.defaultSpeed).flatMap(PlaybackSpeed.init(rawValue:)) ?? .natural
        hasCompletedOnboarding = defaults.bool(forKey: Keys.onboarding)
        reverseFlashcards = defaults.bool(forKey: Keys.reverseFlashcards)
        let gap = defaults.integer(forKey: Keys.thinkingGap)
        thinkingGap = Self.thinkingGaps.contains(gap) ? gap : 5
        recallSpeed = defaults.string(forKey: Keys.recallSpeed).flatMap(PlaybackSpeed.init(rawValue:)) ?? .slow
        playTranslationTwice = defaults.bool(forKey: Keys.playTwice)
        recallSessionLength = defaults.string(forKey: Keys.recallLength).flatMap(RecallSessionLength.init(rawValue:)) ?? .twenty
        hasSeenRecallHint = defaults.bool(forKey: Keys.recallHint)
        reminderEnabled = defaults.bool(forKey: Keys.reminderEnabled)
        reminderTime = defaults.data(forKey: Keys.reminderTime)
            .flatMap { try? JSONDecoder().decode(ReminderTime.self, from: $0) } ?? .default
        perLanguage = defaults.data(forKey: Keys.perLanguage)
            .flatMap { try? JSONDecoder().decode([String: LanguageSettings].self, from: $0) } ?? [:]
    }

    func settings(for languageCode: String) -> LanguageSettings {
        if let stored = perLanguage[languageCode] {
            return stored
        }
        // 1.x had one global formality; "formal" becomes polite.
        var settings = LanguageSettings()
        if defaults.string(forKey: Keys.legacyFormality) == "formal" {
            settings.register = .polite
        }
        return settings
    }

    func update(_ settings: LanguageSettings, for languageCode: String) {
        perLanguage[languageCode] = settings
    }

    /// The thinking gaps offered in Settings, in seconds.
    static let thinkingGaps = [3, 5, 8]

    private enum Keys {
        static let currentLanguage = "currentLanguageCode"
        static let autoPlay = "autoPlayAudio"
        static let legacyFormality = "formality"
        static let defaultSpeed = "settings.defaultSpeed"
        static let perLanguage = "settings.perLanguage"
        static let onboarding = "settings.onboardingCompleted"
        static let reverseFlashcards = "settings.reverseFlashcards"
        static let thinkingGap = "settings.thinkingGap"
        static let recallSpeed = "settings.recallSpeed"
        static let playTwice = "settings.playTranslationTwice"
        static let recallLength = "settings.recallSessionLength"
        static let recallHint = "settings.hasSeenRecallHint"
        static let reminderEnabled = "settings.reminderEnabled"
        static let reminderTime = "settings.reminderTime"
    }
}
