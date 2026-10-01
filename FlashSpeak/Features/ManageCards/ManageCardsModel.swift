import Foundation
import Observation
import SwiftData

/// Manage cards: every phrase in the current language by section, with
/// search, sort, play, delete with Undo, and hide/restore for presets.
@MainActor
@Observable
final class ManageCardsModel {
    private(set) var sections: [PhraseSection] = [.userPhrases]
    private(set) var rows: [Phrase] = []
    private(set) var totalCount = 0
    private(set) var playingID: PersistentIdentifier?
    /// The phrase just deleted, while Undo is offered.
    private(set) var recentlyDeleted: Phrase?
    private(set) var errorMessage: String?

    var section: PhraseSection = .userPhrases {
        didSet {
            if section != oldValue {
                reload()
            }
        }
    }

    var sort: PhraseSort = .newest {
        didSet {
            if sort != oldValue {
                reload()
            }
        }
    }

    var searchText = "" {
        didSet {
            if searchText != oldValue {
                applySearch()
            }
        }
    }

    @ObservationIgnored let dependencies: AppDependencies
    @ObservationIgnored private var all: [Phrase] = []
    @ObservationIgnored private var undoExpiry: Task<Void, Never>?

    static let undoDuration: Duration = .seconds(5)

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var languageCode: String {
        dependencies.settings.currentLanguageCode
    }

    var theme: LanguageTheme {
        LanguageTheme.forCode(languageCode) ?? .mandarin
    }

    var isPresetSection: Bool {
        if case .preset = section {
            return true
        }
        return false
    }

    // MARK: - Loading

    func reload() {
        sections = [.userPhrases] + PhraseSection.startedPresets(in: languageCode, phrases: dependencies.phrases)
        if !sections.contains(section) {
            section = .userPhrases
        }
        do {
            all = try dependencies.phrases.phrases(in: languageCode, section: section, sort: sort)
            errorMessage = nil
        } catch {
            all = []
            errorMessage = "Couldn't load your phrases."
        }
        totalCount = all.count
        applySearch()
    }

    private func applySearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            rows = all
            return
        }
        rows = all.filter { phrase in
            [phrase.englishText, phrase.targetText, phrase.pronunciation, phrase.reading ?? ""]
                .contains { $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        }
    }

    // MARK: - Actions

    func play(_ phrase: Phrase) {
        let id = phrase.persistentModelID
        dependencies.speech.stop()
        if playingID == id {
            playingID = nil
            return
        }
        playingID = id
        Task {
            await dependencies.speech.speak(
                phrase.targetText,
                role: .target(phrase.languageCode),
                speed: dependencies.settings.defaultSpeed
            )
            if playingID == id {
                playingID = nil
            }
        }
    }

    func stopPlayback() {
        dependencies.speech.stop()
        playingID = nil
    }

    /// Soft-deletes and offers Undo for a few seconds.
    func delete(_ phrase: Phrase, now: Date = .now) {
        do {
            try dependencies.phrases.softDelete(phrase, at: now)
        } catch {
            errorMessage = "Couldn't delete the phrase."
            return
        }
        recentlyDeleted = phrase
        reload()
        undoExpiry?.cancel()
        undoExpiry = Task { [weak self] in
            try? await Task.sleep(for: Self.undoDuration)
            guard !Task.isCancelled else { return }
            self?.recentlyDeleted = nil
        }
    }

    func undoDelete() {
        guard let phrase = recentlyDeleted else { return }
        undoExpiry?.cancel()
        try? dependencies.phrases.restore(phrase)
        recentlyDeleted = nil
        reload()
    }

    /// Preset items are hidden from review instead of deleted.
    func toggleHidden(_ phrase: Phrase, now: Date = .now) {
        phrase.hiddenFromReview.toggle()
        phrase.updatedAt = now
        try? dependencies.phrases.save()
        reload()
    }

    /// The text the user must type to delete everything in this language.
    var deleteAllConfirmation: String {
        theme.displayName
    }

    func canDeleteAll(typed: String) -> Bool {
        typed.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(deleteAllConfirmation) == .orderedSame
    }

    /// Soft-deletes every phrase in the language, presets included.
    func deleteAll(typed: String, now: Date = .now) {
        guard canDeleteAll(typed: typed) else { return }
        let everything = (try? dependencies.phrases.phrases(in: languageCode, section: .all, sort: .newest)) ?? []
        for phrase in everything {
            try? dependencies.phrases.softDelete(phrase, at: now)
        }
        recentlyDeleted = nil
        reload()
    }
}
