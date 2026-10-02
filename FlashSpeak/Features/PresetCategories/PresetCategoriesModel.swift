import Foundation
import Observation

/// The preset categories for the current language, which review sets each
/// is in, and the add or remove waiting for confirmation.
@MainActor
@Observable
final class PresetCategoriesModel {
    /// An add or remove the user tapped, waiting for confirmation.
    struct PendingChange: Equatable {
        let category: PresetCategoryContent
        let set: PresetLibrary.ReviewSet
        let isAdding: Bool
        /// Whether the category is also in the other set.
        let isInOtherSet: Bool

        var title: String {
            let count = category.items.count
            return isAdding
                ? "Add \(count) cards to \(set.title.lowercased())?"
                : "Remove \(category.title) from \(set.title.lowercased())?"
        }

        var message: String {
            let count = category.items.count
            switch (set, isAdding) {
            case (.flashcards, true):
                return "New cards are introduced a few a day, up to your daily limit."
            case (.recall, true):
                return "They join your audio recall sessions."
            case (.flashcards, false):
                let rest = isInOtherSet ? "They stay in audio recall." : "They'll be deleted."
                return "Your progress on these \(count) cards will be reset. \(rest)"
            case (.recall, false):
                return isInOtherSet ? "They stay in flashcards with their progress." : "These \(count) cards will be deleted."
            }
        }

        var confirmTitle: String {
            isAdding ? "Add to \(set.title.lowercased())" : "Remove from \(set.title.lowercased())"
        }
    }

    private(set) var categories: [PresetCategoryContent] = []
    private(set) var memberships: [String: PresetLibrary.Membership] = [:]
    var pendingChange: PendingChange?
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
        memberships = Dictionary(uniqueKeysWithValues: categories.map {
            ($0.id, library.membership(of: $0.id, in: languageCode))
        })
    }

    func membership(of category: PresetCategoryContent) -> PresetLibrary.Membership {
        memberships[category.id] ?? PresetLibrary.Membership()
    }

    /// Asks to add the category to the set, or remove it if it's already in.
    func toggle(_ category: PresetCategoryContent, in set: PresetLibrary.ReviewSet) {
        let membership = membership(of: category)
        let other: PresetLibrary.ReviewSet = set == .flashcards ? .recall : .flashcards
        pendingChange = PendingChange(
            category: category,
            set: set,
            isAdding: !membership.contains(set),
            isInOtherSet: membership.contains(other)
        )
    }

    /// The change waiting for confirmation, if it's for this category.
    func pendingChange(for category: PresetCategoryContent) -> PendingChange? {
        pendingChange?.category == category ? pendingChange : nil
    }

    func dismissChange() {
        pendingChange = nil
    }

    func confirm() {
        guard let change = pendingChange else { return }
        pendingChange = nil
        let id = change.category.id
        if change.isAdding {
            run { try library.add(id, to: change.set, in: languageCode) }
        } else {
            run { try library.remove(id, from: change.set, in: languageCode) }
        }
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
