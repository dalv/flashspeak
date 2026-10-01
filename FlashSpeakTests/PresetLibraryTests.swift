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

    @Test func startingACategoryCreatesPresetCards() throws {
        let dependencies = try AppDependencies.test(presets: Self.catalog(version: 1))
        let library = dependencies.presetLibrary
        #expect(library.status(of: "numbers", in: "zh-CN") == .notStarted)

        try library.start("numbers", in: "zh-CN", now: now)

        let cards = try dependencies.phrases.phrases(in: "zh-CN", section: .preset("numbers"), sort: .oldest)
        #expect(cards.map(\.presetItemKey) == ["1", "2"])
        #expect(cards.allSatisfy { $0.phraseSource == .preset && $0.presetContentVersion == 1 })
        #expect(cards.first?.gloss.first?.english == "one")
        #expect(cards.last?.usageNote == "两 before a measure word.")
        #expect(library.status(of: "numbers", in: "zh-CN") == .learning)
        #expect(library.status(of: "days", in: "zh-CN") == .notStarted)
        // Presets aren't user phrases.
        #expect(try dependencies.phrases.phrases(in: "zh-CN", section: .userPhrases, sort: .newest).isEmpty)
    }

    @Test func pauseHidesCardsAndKeepsHistoryThenResumes() throws {
        let dependencies = try AppDependencies.test(presets: Self.catalog(version: 1))
        let library = dependencies.presetLibrary
        try library.start("numbers", in: "zh-CN", now: now)
        let card = try #require(dependencies.phrases.phrases(in: "zh-CN", section: .preset("numbers"), sort: .oldest).first)
        let reviewed = dependencies.scheduler.next(card.cardState, rating: .easy, now: now)
        card.cardState = reviewed

        try library.pause("numbers", in: "zh-CN")
        #expect(library.status(of: "numbers", in: "zh-CN") == .paused)
        #expect(try dependencies.phrases.due(in: "zh-CN", section: .all, now: now.addingTimeInterval(86400 * 365), newLimit: 10).isEmpty)

        try library.start("numbers", in: "zh-CN", now: now)
        #expect(library.status(of: "numbers", in: "zh-CN") == .learning)
        #expect(try dependencies.phrases.phrases(in: "zh-CN", section: .preset("numbers"), sort: .oldest).count == 2)
        #expect(card.nextReviewAt == reviewed.due)
    }

    @Test func correctionsUpdateTextAndKeepTheSchedule() throws {
        let original = try AppDependencies.test(presets: Self.catalog(version: 1))
        try original.presetLibrary.start("numbers", in: "zh-CN", now: now)
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
