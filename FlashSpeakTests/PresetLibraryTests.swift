@testable import FlashSpeak
import Foundation
import SwiftData
import Testing

@MainActor
struct PresetLibraryTests {
    private static func catalog(version: Int, two: String = "二") throws -> PresetCatalog {
        let json = """
        {"language": "zh-CN", "contentVersion": \(version), "reviewed": false, "categories": [
          {"id": "numbers", "items": [
            {"key": "1", "english": "1", "targetText": "一", "romanization": "yī", "reading": null,
             "gloss": [{"target": "一", "romanization": "yī", "english": "one"}], "literal": "one", "usageNote": null, "level": 1},
            {"key": "2", "english": "2", "targetText": "\(two)", "romanization": "èr", "reading": null,
             "gloss": [], "literal": "two", "usageNote": "两 before a measure word.", "level": 1}
          ]},
          {"id": "days", "items": [
            {"key": "monday", "english": "Monday", "targetText": "星期一", "romanization": "xīngqīyī", "reading": null,
             "gloss": [], "literal": "week one", "usageNote": null, "level": 1}
          ]}
        ]}
        """
        return try PresetCatalog(files: [JSONDecoder().decode(PresetFile.self, from: Data(json.utf8))])
    }

    let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func cards(_ dependencies: AppDependencies, _ category: String = "numbers") throws -> [Phrase] {
        try dependencies.phrases.phrases(in: "zh-CN", section: .preset(category), sort: .oldest)
    }

    private func recallQueue(_ dependencies: AppDependencies) throws -> [Phrase] {
        let all = try dependencies.phrases.phrases(in: "zh-CN", section: .all, sort: .newest)
        return RecallQueue.make(from: all, length: .all)
    }

    private func dueCards(_ dependencies: AppDependencies) throws -> [Phrase] {
        try dependencies.phrases.due(in: "zh-CN", section: .all, now: now, newLimit: 100)
    }

    @Test func aCategoryNotAddedIsInNeitherSet() throws {
        let dependencies = try AppDependencies.test(presets: Self.catalog(version: 1))
        #expect(dependencies.presetLibrary.membership(of: "numbers", in: "zh-CN") == .init())
        #expect(try cards(dependencies).isEmpty)
        #expect(try dueCards(dependencies).isEmpty)
        #expect(try recallQueue(dependencies).isEmpty)
    }

    @Test func addingToFlashcardsCreatesPresetCardsOnlyInFlashcards() throws {
        let dependencies = try AppDependencies.test(presets: Self.catalog(version: 1))
        let library = dependencies.presetLibrary

        try library.add("numbers", to: .flashcards, in: "zh-CN", now: now)

        let cards = try cards(dependencies)
        #expect(cards.map(\.presetItemKey) == ["1", "2"])
        #expect(cards.allSatisfy { $0.phraseSource == .preset && $0.presetContentVersion == 1 })
        #expect(cards.first?.gloss.first?.english == "one")
        #expect(cards.last?.usageNote == "两 before a measure word.")
        #expect(library.membership(of: "numbers", in: "zh-CN") == .init(flashcards: true))
        #expect(library.membership(of: "days", in: "zh-CN") == .init())
        #expect(try dueCards(dependencies).count == 2)
        #expect(try recallQueue(dependencies).isEmpty)
        // Presets aren't user phrases.
        #expect(try dependencies.phrases.phrases(in: "zh-CN", section: .userPhrases, sort: .newest).isEmpty)
    }

    @Test func addingToRecallThenFlashcardsReusesTheCards() throws {
        let dependencies = try AppDependencies.test(presets: Self.catalog(version: 1))
        let library = dependencies.presetLibrary

        try library.add("numbers", to: .recall, in: "zh-CN", now: now)
        #expect(library.membership(of: "numbers", in: "zh-CN") == .init(recall: true))
        #expect(try dueCards(dependencies).isEmpty)
        #expect(try recallQueue(dependencies).count == 2)

        try library.add("numbers", to: .flashcards, in: "zh-CN", now: now)
        #expect(library.membership(of: "numbers", in: "zh-CN") == .init(flashcards: true, recall: true))
        #expect(try cards(dependencies).count == 2)
        #expect(try dueCards(dependencies).count == 2)
    }

    @Test func removingFromFlashcardsResetsProgressAndKeepsRecall() throws {
        let dependencies = try AppDependencies.test(presets: Self.catalog(version: 1))
        let library = dependencies.presetLibrary
        try library.add("numbers", to: .flashcards, in: "zh-CN", now: now)
        try library.add("numbers", to: .recall, in: "zh-CN", now: now)
        let card = try #require(cards(dependencies).first)
        card.cardState = dependencies.scheduler.next(card.cardState, rating: .easy, now: now)

        try library.remove("numbers", from: .flashcards, in: "zh-CN", now: now)

        #expect(library.membership(of: "numbers", in: "zh-CN") == .init(recall: true))
        #expect(card.cardState.phase == .new)
        #expect(try dueCards(dependencies).isEmpty)
        #expect(try recallQueue(dependencies).count == 2)
    }

    @Test func removingFromRecallKeepsFlashcardProgress() throws {
        let dependencies = try AppDependencies.test(presets: Self.catalog(version: 1))
        let library = dependencies.presetLibrary
        try library.add("numbers", to: .flashcards, in: "zh-CN", now: now)
        try library.add("numbers", to: .recall, in: "zh-CN", now: now)
        let card = try #require(cards(dependencies).first)
        let reviewed = dependencies.scheduler.next(card.cardState, rating: .easy, now: now)
        card.cardState = reviewed

        try library.remove("numbers", from: .recall, in: "zh-CN", now: now)

        #expect(library.membership(of: "numbers", in: "zh-CN") == .init(flashcards: true))
        #expect(card.nextReviewAt == reviewed.due)
        #expect(try recallQueue(dependencies).isEmpty)
    }

    @Test func removingFromBothDeletesAndAddingAgainStartsFresh() throws {
        let dependencies = try AppDependencies.test(presets: Self.catalog(version: 1))
        let library = dependencies.presetLibrary
        try library.add("numbers", to: .recall, in: "zh-CN", now: now)
        let original = try cards(dependencies)

        try library.remove("numbers", from: .recall, in: "zh-CN", now: now)
        #expect(try cards(dependencies).isEmpty)
        #expect(original.allSatisfy { $0.deletedAt != nil })
        #expect(library.membership(of: "numbers", in: "zh-CN") == .init())

        try library.add("numbers", to: .flashcards, in: "zh-CN", now: now)
        let fresh = try cards(dependencies)
        #expect(fresh.count == 2)
        #expect(Set(fresh.map(\.stableID)).isDisjoint(with: original.map(\.stableID)))
        #expect(library.membership(of: "numbers", in: "zh-CN") == .init(flashcards: true))
    }

    @Test func pausedCategoriesFromTheOldDesignAreRemoved() throws {
        let dependencies = try AppDependencies.test(presets: Self.catalog(version: 1))
        let library = dependencies.presetLibrary
        try library.add("numbers", to: .flashcards, in: "zh-CN", now: now)
        try library.add("numbers", to: .recall, in: "zh-CN", now: now)
        try library.add("days", to: .flashcards, in: "zh-CN", now: now)
        try library.add("days", to: .recall, in: "zh-CN", now: now)
        // Old Pause: every card in the category hidden.
        for card in try cards(dependencies) { card.hiddenFromReview = true }

        try library.removePausedCategories(now: now)

        #expect(try cards(dependencies).isEmpty)
        #expect(try cards(dependencies, "days").count == 1)
    }

    @Test func correctionsUpdateTextAndKeepTheSchedule() throws {
        let original = try AppDependencies.test(presets: Self.catalog(version: 1))
        try original.presetLibrary.add("numbers", to: .flashcards, in: "zh-CN", now: now)
        let card = try #require(original.phrases.phrases(in: "zh-CN", section: .preset("numbers"), sort: .oldest).last)
        let reviewed = original.scheduler.next(card.cardState, rating: .easy, now: now)
        card.cardState = reviewed

        // A later app version ships corrected content over the same store.
        let corrected = try PresetLibrary(catalog: Self.catalog(version: 2, two: "两"), phrases: original.phrases)
        try corrected.applyCorrections(now: now)

        #expect(card.targetText == "两")
        #expect(card.presetContentVersion == 2)
        #expect(card.nextReviewAt == reviewed.due)
        #expect(card.fsrsStability == reviewed.stability)
    }

    @Test func bundledContentCoversEveryLanguageAndCategory() {
        let catalog = PresetCatalog.bundled()
        for code in Language.supportedCodes {
            let ids = catalog.categories(for: code).map(\.id)
            #expect(ids == PresetCategoryKind.allCases.map(\.rawValue), "\(code)")
            let numbers = catalog.category("numbers", in: code)?.items.count ?? 0
            #expect(numbers == (code == "ko" ? 63 : 40), "\(code)")
        }
    }
}
