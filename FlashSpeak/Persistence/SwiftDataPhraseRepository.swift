import Foundation
import SwiftData

/// `PhraseRepository` on a SwiftData context. Previews and tests use it
/// with an in-memory container (`ModelContainer.inMemory()`).
@MainActor
final class SwiftDataPhraseRepository: PhraseRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func phrases(in languageCode: String, section: PhraseSection, sort: PhraseSort) throws -> [Phrase] {
        let result = try fetchLive(in: languageCode).filter { matches($0, section) }
        return sorted(result, by: sort)
    }

    func due(in languageCode: String, section: PhraseSection, now: Date, newLimit: Int) throws -> [Phrase] {
        let candidates = try fetchLive(in: languageCode)
            .filter { matches($0, section) && !$0.hiddenFromReview }
        let isNew: (Phrase) -> Bool = { ($0.fsrsState ?? 0) == CardState.Phase.new.rawValue }

        let due = candidates
            .filter { !isNew($0) && $0.nextReviewAt <= now }
            .sorted { $0.nextReviewAt < $1.nextReviewAt }
        let new = candidates
            .filter(isNew)
            .sorted { $0.createdAt < $1.createdAt }
            .prefix(max(newLimit, 0))
        return due + new
    }

    func insert(_ phrase: Phrase) throws {
        context.insert(phrase)
        try context.save()
    }

    func softDelete(_ phrase: Phrase, at date: Date) throws {
        phrase.deletedAt = date
        phrase.updatedAt = date
        try context.save()
    }

    func purgeDeleted(olderThan date: Date) throws {
        let descriptor = FetchDescriptor<Phrase>(predicate: #Predicate { phrase in
            phrase.deletedAt != nil
        })
        for phrase in try context.fetch(descriptor) where (phrase.deletedAt ?? date) < date {
            context.delete(phrase)
        }
        try context.save()
    }

    func save() throws {
        try context.save()
    }

    // MARK: - Private

    private func fetchLive(in languageCode: String) throws -> [Phrase] {
        guard Language.supportedCodes.contains(languageCode) else { return [] }
        let descriptor = FetchDescriptor<Phrase>(predicate: #Predicate { phrase in
            phrase.languageCode == languageCode && phrase.deletedAt == nil
        })
        return try context.fetch(descriptor)
    }

    private func matches(_ phrase: Phrase, _ section: PhraseSection) -> Bool {
        switch section {
        case .all: true
        case .userPhrases: phrase.presetCategory == nil
        case let .preset(id): phrase.presetCategory == id
        }
    }

    private func sorted(_ phrases: [Phrase], by sort: PhraseSort) -> [Phrase] {
        switch sort {
        case .newest:
            phrases.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            phrases.sorted { $0.createdAt < $1.createdAt }
        case .alphabetical:
            phrases.sorted { $0.englishText.localizedStandardCompare($1.englishText) == .orderedAscending }
        case .level:
            phrases.sorted { ($0.level ?? 0, $1.createdAt) < ($1.level ?? 0, $0.createdAt) }
        }
    }
}
