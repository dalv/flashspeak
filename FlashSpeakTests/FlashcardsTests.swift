@testable import FlashSpeak
import Foundation
import SwiftData
import Testing

@MainActor
struct FlashcardsTests {
    let dependencies = AppDependencies.test()
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    @discardableResult
    private func add(
        _ english: String,
        preset: String? = nil,
        phase: CardState.Phase = .new,
        due: TimeInterval = 0,
        created: TimeInterval = 0
    ) throws -> Phrase {
        let phrase = Phrase(englishText: english, targetText: english, languageCode: "zh-CN")
        phrase.presetCategory = preset
        phrase.fsrsState = phase.rawValue
        phrase.nextReviewAt = now.addingTimeInterval(due)
        phrase.createdAt = now.addingTimeInterval(created)
        try dependencies.phrases.insert(phrase)
        return phrase
    }

    private func model() -> FlashcardsModel {
        dependencies.settings.currentLanguageCode = "zh-CN"
        dependencies.settings.autoPlay = false
        let model = FlashcardsModel(dependencies: dependencies)
        model.load(now: now)
        return model
    }

    @Test func dueCardsComeBeforeNewCards() throws {
        try add("new", created: -10)
        try add("due", phase: .review, due: -60)
        #expect(model().queue.map(\.englishText) == ["due", "new"])
    }

    @Test func ratingUpdatesTheScheduleAndAppendsAReview() throws {
        let phrase = try add("Turn left")
        let model = model()
        model.flip()
        model.rate(.easy, now: now)

        #expect(phrase.fsrsState != CardState.Phase.new.rawValue)
        #expect(phrase.nextReviewAt > now)
        #expect(phrase.schedulerVersion == dependencies.scheduler.version)
        #expect(phrase.reviews?.count == 1)
        #expect(phrase.reviews?.first?.mode == ReviewMode.flashcard.rawValue)
        #expect(model.reviewedCount == 1)
    }

    @Test func ratingNeedsTheCardFlipped() throws {
        let phrase = try add("Turn left")
        let model = model()
        model.rate(.easy, now: now)
        #expect(phrase.reviews?.isEmpty ?? true)
        #expect(model.position == 0)
    }

    @Test func hardBringsANewCardBackInTheSameSession() throws {
        try add("Turn left")
        let model = model()
        model.flip()
        model.rate(.hard, now: now)

        #expect(model.current?.englishText == "Turn left")
        model.flip()
        model.rate(.easy, now: now.addingTimeInterval(60))
        #expect(model.isFinished)
    }

    @Test func newCardsIntroducedTodayCountAgainstTheDailyLimit() throws {
        var settings = dependencies.settings.settings(for: "zh-CN")
        settings.dailyNewCardLimit = 2
        dependencies.settings.update(settings, for: "zh-CN")
        for index in 0 ..< 4 {
            try add("new \(index)", created: Double(index))
        }

        let first = model()
        #expect(first.queue.count == 2)
        first.flip()
        first.rate(.easy, now: now)

        // Reopening later the same day offers only the one remaining new card.
        let second = FlashcardsModel(dependencies: dependencies)
        second.load(now: now.addingTimeInterval(60))
        #expect(second.queue.filter { $0.fsrsState == CardState.Phase.new.rawValue }.count == 1)
    }

    @Test func hiddenAndOtherSectionsAreLeftOut() throws {
        try add("Turn left")
        try add("one", preset: "numbers")
        let hidden = try add("two", preset: "numbers")
        hidden.hiddenFromReview = true

        let model = model()
        #expect(model.sections == [.all, .userPhrases, .preset("numbers")])
        model.section = .preset("numbers")
        #expect(model.queue.map(\.englishText) == ["one"])
    }

    @Test func intervalText() throws {
        let calendar = Calendar(identifier: .gregorian)
        let base = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 9)))
        #expect(ReviewIntervalText.text(from: base, to: base.addingTimeInterval(60), calendar: calendar) == "Again soon")
        #expect(ReviewIntervalText.text(from: base, to: base.addingTimeInterval(5 * 3600), calendar: calendar) == "Later today")
        #expect(ReviewIntervalText.text(from: base, to: base.addingTimeInterval(86400), calendar: calendar) == "Tomorrow")
        #expect(ReviewIntervalText.text(from: base, to: base.addingTimeInterval(4 * 86400), calendar: calendar) == "In 4 days")
        #expect(ReviewIntervalText.text(from: base, to: base.addingTimeInterval(65 * 86400), calendar: calendar) == "In 2 months")
        #expect(ReviewIntervalText.text(from: base, to: base.addingTimeInterval(400 * 86400), calendar: calendar) == "In 1 year")
    }

    @Test func newReviewSettingsHaveTheirDefaults() {
        let settings = dependencies.settings
        #expect(settings.reverseFlashcards == false)
        #expect(settings.thinkingGap == 5)
        #expect(settings.recallSpeed == .slow)
        #expect(settings.playTranslationTwice == false)
        #expect(settings.recallSessionLength == .twenty)
        #expect(settings.reminderEnabled == false)
        #expect(settings.reminderTime == .default)
    }
}
