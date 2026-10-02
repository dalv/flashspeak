import Foundation

/// Adds preset categories to flashcards and audio recall, and removes them.
/// A category is in a set once its items are Phrase records (source
/// `preset`) not excluded from that set; removing it from both deletes its
/// cards (decision 0022).
@MainActor
struct PresetLibrary {
    enum ReviewSet: Equatable {
        case flashcards
        case recall
    }

    /// Which sets a category is in.
    struct Membership: Equatable {
        var flashcards = false
        var recall = false

        func contains(_ set: ReviewSet) -> Bool {
            switch set {
            case .flashcards: flashcards
            case .recall: recall
            }
        }
    }

    let catalog: PresetCatalog
    let phrases: any PhraseRepository

    func membership(of categoryID: String, in languageCode: String) -> Membership {
        let stored = storedItems(categoryID, in: languageCode)
        return Membership(
            flashcards: stored.contains { !$0.excludedFromFlashcards },
            recall: stored.contains { !$0.excludedFromRecall }
        )
    }

    /// Adds the category to one set: creates missing cards (out of the
    /// other set unless the category is already in it) and includes the rest.
    func add(_ categoryID: String, to set: ReviewSet, in languageCode: String, now: Date = .now) throws {
        guard let file = catalog.file(for: languageCode),
              let category = catalog.category(categoryID, in: languageCode) else { return }
        let current = membership(of: categoryID, in: languageCode)
        let existing = Dictionary(
            storedItems(categoryID, in: languageCode).compactMap { phrase in phrase.presetItemKey.map { ($0, phrase) } },
            uniquingKeysWith: { first, _ in first }
        )
        for (index, item) in category.items.enumerated() {
            if let phrase = existing[item.key] {
                Self.include(phrase, in: set)
                phrase.updatedAt = now
                continue
            }
            let phrase = Phrase(
                englishText: item.english,
                targetText: item.targetText,
                pronunciation: item.romanization ?? "",
                literalTranslation: item.literal,
                languageCode: languageCode
            )
            phrase.stableID = UUID()
            phrase.phraseSource = .preset
            phrase.presetCategory = categoryID
            phrase.presetItemKey = item.key
            phrase.presetContentVersion = file.contentVersion
            Self.apply(item, to: phrase)
            // Presets are in neither set until added.
            phrase.excludedFromFlashcards = !current.flashcards
            phrase.excludedFromRecall = !current.recall
            Self.include(phrase, in: set)
            // Catalog order, so new cards are introduced in that order.
            phrase.createdAt = now.addingTimeInterval(Double(index) / 1000)
            phrase.updatedAt = now
            phrase.cardState = .new(due: now)
            try phrases.insert(phrase)
        }
        try phrases.save()
    }

    /// Takes the category out of one set. Leaving flashcards resets the
    /// cards' progress; cards in neither set are deleted.
    func remove(_ categoryID: String, from set: ReviewSet, in languageCode: String, now: Date = .now) throws {
        for phrase in storedItems(categoryID, in: languageCode) {
            switch set {
            case .flashcards:
                phrase.excludedFromFlashcards = true
                phrase.cardState = .new(due: now)
            case .recall:
                phrase.excludedFromRecall = true
            }
            phrase.updatedAt = now
            if phrase.excludedFromFlashcards && phrase.excludedFromRecall {
                try phrases.softDelete(phrase, at: now)
            }
        }
        try phrases.save()
    }

    /// Deletes categories paused under the old Start/Pause design (every
    /// card hidden), so they show as not added. Run once, at launch.
    func removePausedCategories(now: Date = .now) throws {
        for code in Language.supportedCodes {
            let stored = try phrases.phrases(in: code, section: .all, sort: .oldest).filter(\.isPreset)
            let byCategory = Dictionary(grouping: stored) { $0.presetCategory ?? "" }
            for cards in byCategory.values where cards.allSatisfy(\.hiddenFromReview) {
                for phrase in cards {
                    try phrases.softDelete(phrase, at: now)
                }
            }
        }
    }

    /// Updates cards made from an older content version, keeping their
    /// schedule and history. Run at launch.
    func applyCorrections(now: Date = .now) throws {
        for code in Language.supportedCodes {
            guard let file = catalog.file(for: code) else { continue }
            let stored = try phrases.phrases(in: code, section: .all, sort: .newest).filter(\.isPreset)
            var changed = false
            for phrase in stored where (phrase.presetContentVersion ?? 0) < file.contentVersion {
                guard let categoryID = phrase.presetCategory, let key = phrase.presetItemKey,
                      let item = catalog.category(categoryID, in: code)?.items.first(where: { $0.key == key }) else { continue }
                phrase.englishText = item.english
                phrase.targetText = item.targetText
                phrase.pronunciation = item.romanization ?? ""
                phrase.literalTranslation = item.literal
                Self.apply(item, to: phrase)
                phrase.presetContentVersion = file.contentVersion
                phrase.updatedAt = now
                changed = true
            }
            if changed { try phrases.save() }
        }
    }

    private func storedItems(_ categoryID: String, in languageCode: String) -> [Phrase] {
        (try? phrases.phrases(in: languageCode, section: .preset(categoryID), sort: .oldest)) ?? []
    }

    private static func include(_ phrase: Phrase, in set: ReviewSet) {
        switch set {
        case .flashcards: phrase.excludedFromFlashcards = false
        case .recall: phrase.excludedFromRecall = false
        }
    }

    private static func apply(_ item: PresetItem, to phrase: Phrase) {
        phrase.reading = item.reading
        phrase.gloss = item.gloss
        phrase.usageNote = item.usageNote
        phrase.level = item.level
    }
}
