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

    private enum Keys {
        static let currentLanguage = "currentLanguageCode"
        static let autoPlay = "autoPlayAudio"
        static let legacyFormality = "formality"
        static let defaultSpeed = "settings.defaultSpeed"
        static let perLanguage = "settings.perLanguage"
        static let onboarding = "settings.onboardingCompleted"
    }
}
