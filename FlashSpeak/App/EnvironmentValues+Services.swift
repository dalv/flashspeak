import SwiftUI

/// One environment value per service. Defaults are inert fakes, so a view
/// without `.dependencies(_:)` still renders; the app and Previews always
/// inject real or preview dependencies.
extension EnvironmentValues {
    @Entry var phraseRepository: any PhraseRepository = FakePhraseRepository()
    @Entry var reviewRepository: any ReviewRepository = FakeReviewRepository()
    @Entry var scheduler: any Scheduler = FSRSScheduler()
    @Entry var translationClient: any TranslationClient = FakeTranslationClient()
    @Entry var transcriptionService: (any TranscriptionService)? = nil
    @Entry var speechSynthesizer: (any SpeechSynthesizer)? = nil
    @Entry var voiceCatalog: (any VoiceCatalog)? = nil
    @Entry var settingsStore: (any SettingsStore)? = nil
    @Entry var entitlementService: (any EntitlementService)? = nil
    @Entry var usageService: (any UsageService)? = nil
    /// All services, for creating feature view models.
    @Entry var appDependencies: AppDependencies? = nil
}

extension View {
    /// Injects every service and the model container.
    func dependencies(_ dependencies: AppDependencies) -> some View {
        environment(\.phraseRepository, dependencies.phrases)
            .environment(\.reviewRepository, dependencies.reviews)
            .environment(\.scheduler, dependencies.scheduler)
            .environment(\.translationClient, dependencies.translation)
            .environment(\.transcriptionService, dependencies.transcription)
            .environment(\.speechSynthesizer, dependencies.speech)
            .environment(\.voiceCatalog, dependencies.voices)
            .environment(\.settingsStore, dependencies.settings)
            .environment(\.entitlementService, dependencies.entitlements)
            .environment(\.usageService, dependencies.usage)
            .environment(\.appDependencies, dependencies)
            .modelContainer(dependencies.modelContainer)
    }
}
