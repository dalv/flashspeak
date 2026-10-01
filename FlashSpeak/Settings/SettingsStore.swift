/// App preferences. Observable, so views update when a setting changes.
@MainActor
protocol SettingsStore: AnyObject {
    /// One of `Language.supportedCodes`.
    var currentLanguageCode: String { get set }
    var autoPlay: Bool { get set }
    var defaultSpeed: PlaybackSpeed { get set }
    var hasCompletedOnboarding: Bool { get set }

    func settings(for languageCode: String) -> LanguageSettings
    func update(_ settings: LanguageSettings, for languageCode: String)
}
