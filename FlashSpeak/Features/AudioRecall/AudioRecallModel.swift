import Foundation
import Observation

/// Audio recall: choose a section and length, then run a `RecallSession`.
@MainActor
@Observable
final class AudioRecallModel {
    private(set) var sections: [PhraseSection] = [.all]
    private(set) var setCount = 0
    private(set) var session: RecallSession?

    var section: PhraseSection = .all {
        didSet {
            guard section != oldValue else { return }
            refresh()
        }
    }

    @ObservationIgnored let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var languageCode: String {
        dependencies.settings.currentLanguageCode
    }

    var theme: LanguageTheme {
        LanguageTheme.forCode(languageCode) ?? .mandarin
    }

    var length: RecallSessionLength {
        get { dependencies.settings.recallSessionLength }
        set { dependencies.settings.recallSessionLength = newValue }
    }

    var speed: PlaybackSpeed {
        dependencies.settings.recallSpeed
    }

    func refresh() {
        sections = PhraseSection.reviewable(in: languageCode, phrases: dependencies.phrases, set: .recall)
        if !sections.contains(section) {
            section = .all
        }
        setCount = reviewablePhrases().count
    }

    func start(
        now: Date = .now,
        sleep: @escaping RecallSession.Sleep = { try await Task.sleep(for: $0) }
    ) {
        session?.stop()
        let queue = RecallQueue.make(from: reviewablePhrases(), length: length, now: now)
        let session = RecallSession(phrases: queue, setCount: setCount, dependencies: dependencies, sleep: sleep)
        self.session = session
        session.start()
    }

    func endSession() {
        session?.stop()
        session = nil
        refresh()
    }

    private func reviewablePhrases() -> [Phrase] {
        let phrases = (try? dependencies.phrases.phrases(in: languageCode, section: section, sort: .newest)) ?? []
        return phrases.filter { !$0.hiddenFromReview && !$0.excludedFromRecall }
    }
}
