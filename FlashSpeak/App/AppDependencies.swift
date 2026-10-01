import Foundation
import SwiftData

/// The composition root: one instance of each service. Only `App` creates
/// live services; features read them from the environment.
@MainActor
struct AppDependencies {
    let modelContainer: ModelContainer
    let phrases: any PhraseRepository
    let reviews: any ReviewRepository
    let scheduler: any Scheduler
    let translation: any TranslationClient
    let transcription: any TranscriptionService
    let speech: any SpeechSynthesizer
    let voices: any VoiceCatalog
    let audioSession: any AudioSessionCoordinator
    let settings: any SettingsStore
    let entitlements: any EntitlementService
    let usage: any UsageService
    let embeddings: any EmbeddingProvider

    /// The real app. Throws if the store can't open.
    static func live() throws -> AppDependencies {
        let container = try ModelContainer.app()
        try MigrationRunner.runIfNeeded(context: container.mainContext)

        let audioSession = SystemAudioSessionCoordinator()
        let voices = AppleVoiceCatalog()
        let entitlements = StoreKitEntitlementService()
        return AppDependencies(
            modelContainer: container,
            phrases: SwiftDataPhraseRepository(context: container.mainContext),
            reviews: SwiftDataReviewRepository(context: container.mainContext),
            scheduler: FSRSScheduler(),
            translation: WorkerEndpoint.liveClient(),
            transcription: SpeechAnalyzerTranscriptionService(audioSession: audioSession),
            speech: AppleSpeechSynthesizer(voices: voices, audioSession: audioSession),
            voices: voices,
            audioSession: audioSession,
            settings: UserDefaultsSettingsStore(),
            entitlements: entitlements,
            usage: LocalUsageService { entitlements.isPro },
            embeddings: NLSentenceEmbeddingProvider()
        )
    }

    /// Fakes and an in-memory store with sample phrases in all four languages.
    static func preview(isPro: Bool = false, seeded: Bool = true) -> AppDependencies {
        let container = ModelContainer.inMemory()
        if seeded { PreviewData.seed(container.mainContext) }
        let defaults = UserDefaults(suiteName: "preview") ?? .standard
        let entitlements = FakeEntitlementService(isPro: isPro)
        return AppDependencies(
            modelContainer: container,
            phrases: SwiftDataPhraseRepository(context: container.mainContext),
            reviews: SwiftDataReviewRepository(context: container.mainContext),
            scheduler: FSRSScheduler(),
            translation: FakeTranslationClient(delay: .milliseconds(600)),
            transcription: FakeTranscriptionService(),
            speech: FakeSpeechSynthesizer(),
            voices: AppleVoiceCatalog(),
            audioSession: FakeAudioSessionCoordinator(),
            settings: UserDefaultsSettingsStore(defaults: defaults),
            entitlements: entitlements,
            usage: LocalUsageService(defaults: defaults) { entitlements.isPro },
            embeddings: NLSentenceEmbeddingProvider()
        )
    }

    /// Like `preview`, but with no delays and an empty store.
    static func test() -> AppDependencies {
        let container = ModelContainer.inMemory()
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)") ?? .standard
        let entitlements = FakeEntitlementService()
        return AppDependencies(
            modelContainer: container,
            phrases: SwiftDataPhraseRepository(context: container.mainContext),
            reviews: SwiftDataReviewRepository(context: container.mainContext),
            scheduler: FSRSScheduler(),
            translation: FakeTranslationClient(),
            transcription: FakeTranscriptionService(),
            speech: FakeSpeechSynthesizer(),
            voices: AppleVoiceCatalog(),
            audioSession: FakeAudioSessionCoordinator(),
            settings: UserDefaultsSettingsStore(defaults: defaults),
            entitlements: entitlements,
            usage: LocalUsageService(defaults: defaults) { entitlements.isPro },
            embeddings: FakeEmbeddingProvider()
        )
    }
}
