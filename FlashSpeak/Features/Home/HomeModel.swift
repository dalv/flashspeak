import Foundation
import Observation

/// Home: the current language and the counts on its tiles.
@MainActor
@Observable
final class HomeModel {
    private(set) var phraseCount = 0
    private(set) var dueCount = 0

    @ObservationIgnored let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var languageCode: String {
        get { dependencies.settings.currentLanguageCode }
        set {
            dependencies.settings.currentLanguageCode = newValue
            refresh()
        }
    }

    var theme: LanguageTheme {
        LanguageTheme.forCode(languageCode) ?? .mandarin
    }

    var isEmpty: Bool {
        phraseCount == 0
    }

    var translationsRemaining: Int? {
        dependencies.usage.translationsRemainingToday
    }

    func refresh(now: Date = .now) {
        let code = languageCode
        let limit = dependencies.settings.settings(for: code).dailyNewCardLimit
        phraseCount = (try? dependencies.phrases.phrases(in: code, section: .all, sort: .newest).count) ?? 0
        dueCount = (try? dependencies.phrases.due(in: code, section: .all, now: now, newLimit: limit).count) ?? 0
    }

    /// Reschedules the daily reminder with a fresh phrase to recall.
    func refreshReminder() async {
        await ReminderPlanner(dependencies: dependencies).reschedule()
    }

    func makeNewPhrase() -> NewPhraseModel {
        NewPhraseModel(dependencies: dependencies)
    }
}
