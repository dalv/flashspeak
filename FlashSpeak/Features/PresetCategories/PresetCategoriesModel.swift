import Foundation
import Observation

/// The preset categories for the current language, with their status.
@MainActor
@Observable
final class PresetCategoriesModel {
    private(set) var categories: [PresetCategoryContent] = []
    private(set) var statuses: [String: PresetLibrary.Status] = [:]
    private(set) var playingKey: String?
    private(set) var errorMessage: String?

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

    private var library: PresetLibrary {
        dependencies.presetLibrary
    }

    func refresh() {
        categories = dependencies.presets.categories(for: languageCode)
        statuses = Dictionary(uniqueKeysWithValues: categories.map {
            ($0.id, library.status(of: $0.id, in: languageCode))
        })
    }

    func status(of category: PresetCategoryContent) -> PresetLibrary.Status {
        statuses[category.id] ?? .notStarted
    }

    func start(_ category: PresetCategoryContent) {
        run { try library.start(category.id, in: languageCode) }
    }

    func pause(_ category: PresetCategoryContent) {
        run { try library.pause(category.id, in: languageCode) }
    }

    func play(_ item: PresetItem) {
        dependencies.speech.stop()
        if playingKey == item.key {
            playingKey = nil
            return
        }
        playingKey = item.key
        Task {
            await dependencies.speech.speak(item.targetText, role: .target(languageCode), speed: dependencies.settings.defaultSpeed)
            if playingKey == item.key { playingKey = nil }
        }
    }

    func stopPlayback() {
        dependencies.speech.stop()
        playingKey = nil
    }

    private func run(_ action: () throws -> Void) {
        do {
            try action()
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't update the category. Try again."
        }
        refresh()
    }
}
