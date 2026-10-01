import Foundation

/// An empty `PhraseRepository` used as the environment default. Previews
/// that need data use `SwiftDataPhraseRepository` on `ModelContainer.inMemory()`.
@MainActor
final class FakePhraseRepository: PhraseRepository {
    nonisolated init() {}

    func phrases(in _: String, section _: PhraseSection, sort _: PhraseSort) throws -> [Phrase] {
        []
    }

    func due(in _: String, section _: PhraseSection, now _: Date, newLimit _: Int) throws -> [Phrase] {
        []
    }

    func insert(_: Phrase) throws {}
    func softDelete(_: Phrase, at _: Date) throws {}
    func purgeDeleted(olderThan _: Date) throws {}
    func save() throws {}
}

/// A `ReviewRepository` that discards reviews.
@MainActor
final class FakeReviewRepository: ReviewRepository {
    nonisolated init() {}

    func append(_: ReviewLog) throws {}

    func newCardsIntroduced(in _: String, since _: Date) throws -> Int {
        0
    }
}
