@testable import FlashSpeak
import Foundation
import SwiftData
import Testing

@MainActor
struct PhraseMigrationTests {
    /// @Model objects need a loaded container, even in tests.
    let context = ModelContext(try! ModelContainer(
        for: Phrase.self, ReviewLog.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ))

    private func legacyPhrase(repetitions: Int, interval: Double, due: Date) -> Phrase {
        let phrase = Phrase(englishText: "How much is this?", targetText: "这个多少钱？", languageCode: "zh-CN")
        context.insert(phrase)
        phrase.repetitions = repetitions
        phrase.interval = interval
        phrase.nextReviewAt = due
        return phrase
    }

    @Test func reviewedLegacyCardStartsInReviewWithItsDueDate() {
        let due = Date(timeIntervalSince1970: 1_800_000_000)
        let phrase = legacyPhrase(repetitions: 3, interval: 12, due: due)

        PhraseMigration.migrate([phrase])

        #expect(phrase.stableID != nil)
        #expect(phrase.phraseSource == .legacy)
        #expect(phrase.updatedAt == phrase.createdAt)
        #expect(phrase.cardState.phase == .review)
        #expect(phrase.cardState.stability == 12)
        #expect(phrase.cardState.difficulty == PhraseMigration.legacyDifficulty)
        #expect(phrase.nextReviewAt == due)
    }

    @Test func unreviewedLegacyCardStartsNew() {
        let phrase = legacyPhrase(repetitions: 0, interval: 0, due: .now)
        PhraseMigration.migrate([phrase])
        #expect(phrase.cardState.phase == .new)
    }

    @Test func shortSM2IntervalGetsMinimumStability() {
        let phrase = legacyPhrase(repetitions: 1, interval: 1.0 / 1440.0, due: .now)
        PhraseMigration.migrate([phrase])
        #expect(phrase.cardState.stability == 1)
    }

    @Test func runningTwiceChangesNothingTheSecondTime() {
        let phrase = legacyPhrase(repetitions: 2, interval: 6, due: .now)
        let id = UUID()
        #expect(PhraseMigration.migrate([phrase], makeID: { id }) == 1)
        #expect(PhraseMigration.migrate([phrase]) == 0)
        #expect(phrase.stableID == id)
    }
}
