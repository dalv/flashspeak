import Foundation

/// Starts, pauses and updates preset categories. A category is in review
/// once its items are Phrase records (source `preset`); pausing hides them
/// and keeps their history (decision 0015).
@MainActor
struct PresetLibrary {
    enum Status: Equatable {
        case notStarted
        case learning
        case paused
    }

    let catalog: PresetCatalog
    let phrases: any PhraseRepository

    func status(of categoryID: String, in languageCode: String) -> Status {
        let stored = storedItems(categoryID, in: languageCode)
        if stored.isEmpty { return .notStarted }
        return stored.allSatisfy(\.hiddenFromReview) ? .paused : .learning
    }

    /// Adds the category to review: creates missing cards, un-hides the rest.
    func start(_ categoryID: String, in languageCode: String, now: Date = .now) throws {
        guard let file = catalog.file(for: languageCode),
              let category = catalog.category(categoryID, in: languageCode) else { return }
        let existing = Dictionary(
            storedItems(categoryID, in: languageCode).compactMap { phrase in phrase.presetItemKey.map { ($0, phrase) } },
            uniquingKeysWith: { first, _ in first }
        )
        for (index, item) in category.items.enumerated() {
            if let phrase = existing[item.key] {
                phrase.hiddenFromReview = false
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
            // Catalog order, so new cards are introduced in that order.
            phrase.createdAt = now.addingTimeInterval(Double(index) / 1000)
            phrase.updatedAt = now
            phrase.cardState = .new(due: now)
            try phrases.insert(phrase)
        }
        try phrases.save()
    }

    /// Takes the category out of review; its cards and history stay.
    func pause(_ categoryID: String, in languageCode: String, now: Date = .now) throws {
        for phrase in storedItems(categoryID, in: languageCode) {
            phrase.hiddenFromReview = true
            phrase.updatedAt = now
        }
        try phrases.save()
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

    private static func apply(_ item: PresetItem, to phrase: Phrase) {
        phrase.reading = item.reading
        phrase.gloss = item.gloss
        phrase.usageNote = item.usageNote
        phrase.level = item.level
    }
}
