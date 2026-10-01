@testable import FlashSpeak
import Foundation
import SwiftData
import Testing

@MainActor
struct PhraseRepositoryTests {
    let container = ModelContainer.inMemory()
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    private var repository: SwiftDataPhraseRepository {
        SwiftDataPhraseRepository(context: container.mainContext)
    }

    @discardableResult
    private func add(
        _ english: String,
        language: String = "zh-CN",
        preset: String? = nil,
        phase: CardState.Phase = .new,
        due: TimeInterval = 0,
        created: TimeInterval = 0
    ) throws -> Phrase {
        let phrase = Phrase(englishText: english, targetText: english, languageCode: language)
        phrase.presetCategory = preset
        phrase.fsrsState = phase.rawValue
        phrase.nextReviewAt = now.addingTimeInterval(due)
        phrase.createdAt = now.addingTimeInterval(created)
        try repository.insert(phrase)
        return phrase
    }

    @Test func sectionsSeparateUserPhrasesFromPresets() throws {
        try add("Turn left")
        try add("one", preset: "numbers")
        try add("Monday", preset: "days")

        #expect(try repository.phrases(in: "zh-CN", section: .userPhrases, sort: .newest).map(\.englishText) == ["Turn left"])
        #expect(try repository.phrases(in: "zh-CN", section: .preset("numbers"), sort: .newest).map(\.englishText) == ["one"])
        #expect(try repository.phrases(in: "zh-CN", section: .all, sort: .newest).count == 3)
    }

    @Test func softDeletedAndOtherLanguagesAreHidden() throws {
        let deleted = try add("Gone")
        try repository.softDelete(deleted, at: now)
        try add("Hola", language: "es")
        try add("Kept")

        #expect(try repository.phrases(in: "zh-CN", section: .all, sort: .newest).map(\.englishText) == ["Kept"])
        #expect(try repository.phrases(in: "es", section: .all, sort: .newest).isEmpty)
    }

    @Test func dueListsOverdueFirstThenLimitedNewCards() throws {
        try add("due later", phase: .review, due: -60)
        try add("most overdue", phase: .review, due: -3600)
        try add("not yet due", phase: .review, due: 3600)
        try add("new 1", created: -300)
        try add("new 2", created: -200)
        try add("new 3", created: -100)
        let hidden = try add("hidden", phase: .review, due: -7200)
        hidden.hiddenFromReview = true

        let due = try repository.due(in: "zh-CN", section: .all, now: now, newLimit: 2)
        #expect(due.map(\.englishText) == ["most overdue", "due later", "new 1", "new 2"])
    }

    @Test func purgeRemovesOnlyOldSoftDeletes() throws {
        let old = try add("old")
        let recent = try add("recent")
        try repository.softDelete(old, at: now.addingTimeInterval(-40 * 86400))
        try repository.softDelete(recent, at: now)

        try repository.purgeDeleted(olderThan: now.addingTimeInterval(-30 * 86400))

        let remaining = try container.mainContext.fetch(FetchDescriptor<Phrase>()).map(\.englishText)
        #expect(remaining == ["recent"])
    }
}
