@testable import FlashSpeak
import Foundation
import SwiftData
import Testing

@MainActor
struct ManageCardsTests {
    let dependencies = AppDependencies.test()

    @discardableResult
    private func add(_ english: String, target: String = "", romanization: String = "", preset: String? = nil) throws -> Phrase {
        let phrase = Phrase(englishText: english, targetText: target.isEmpty ? "[\(english)]" : target, pronunciation: romanization, languageCode: "zh-CN")
        phrase.stableID = UUID()
        phrase.presetCategory = preset
        try dependencies.phrases.insert(phrase)
        return phrase
    }

    private func model() -> ManageCardsModel {
        dependencies.settings.currentLanguageCode = "zh-CN"
        let model = ManageCardsModel(dependencies: dependencies)
        model.reload()
        return model
    }

    @Test func searchMatchesEnglishTranslationAndRomanization() throws {
        try add("How much is this?", target: "这个多少钱?", romanization: "Zhège duōshao qián?")
        try add("Turn left", target: "左转", romanization: "zuǒ zhuǎn")
        let model = model()

        model.searchText = "turn"
        #expect(model.rows.map(\.englishText) == ["Turn left"])
        model.searchText = "多少"
        #expect(model.rows.map(\.englishText) == ["How much is this?"])
        model.searchText = "zuo"
        #expect(model.rows.map(\.englishText) == ["Turn left"])
        model.searchText = ""
        #expect(model.rows.count == 2)
    }

    @Test func deleteCanBeUndone() throws {
        let phrase = try add("Turn left")
        let model = model()

        model.delete(phrase)
        #expect(model.rows.isEmpty)
        #expect(phrase.deletedAt != nil)
        #expect(model.recentlyDeleted === phrase)

        model.undoDelete()
        #expect(model.rows.count == 1)
        #expect(phrase.deletedAt == nil)
        #expect(model.recentlyDeleted == nil)
    }

    @Test func presetItemsAreHiddenNotDeleted() throws {
        try add("Turn left")
        let one = try add("one", preset: "numbers")
        let model = model()
        #expect(model.sections == [.userPhrases, .preset("numbers")])

        model.section = .preset("numbers")
        model.toggleHidden(one)
        #expect(one.hiddenFromReview)
        #expect(one.deletedAt == nil)
        #expect(model.rows.count == 1)

        model.toggleHidden(one)
        #expect(!one.hiddenFromReview)
    }

    @Test func deleteAllNeedsTheLanguageName() throws {
        try add("Turn left")
        try add("one", preset: "numbers")
        let model = model()

        model.deleteAll(typed: "Mandar")
        #expect(model.totalCount == 1)
        model.deleteAll(typed: " mandarin ")
        #expect(try dependencies.phrases.phrases(in: "zh-CN", section: .all, sort: .newest).isEmpty)
    }

    @Test func editingASavedPhraseKeepsItsSchedule() async throws {
        let phrase = try add("Let's take a taxi")
        let due = Date(timeIntervalSince1970: 1_900_000_000)
        phrase.cardState = CardState(phase: .review, stability: 12, difficulty: 4, due: due, lastReview: nil, lapses: 1)

        let result = ResultModel(editing: phrase, dependencies: dependencies)
        await result.retry()

        #expect(phrase.targetText == result.current.targetText)
        #expect(phrase.nextReviewAt == due)
        #expect(phrase.fsrsStability == 12)
        #expect(phrase.fsrsLapses == 1)
        // Not saved a second time.
        #expect(try dependencies.phrases.phrases(in: "zh-CN", section: .all, sort: .newest).count == 1)

        result.apply(result.current, clarification: "to a friend")
        #expect(phrase.clarifications.map(\.text) == ["to a friend"])
    }
}
