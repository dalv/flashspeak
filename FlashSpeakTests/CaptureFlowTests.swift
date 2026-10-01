@testable import FlashSpeak
import Foundation
import SwiftData
import Testing

@MainActor
struct CaptureFlowTests {
    let dependencies = AppDependencies.test()

    private func translated(_ english: String = "Let's take a taxi") async throws -> ResultModel {
        let model = NewPhraseModel(dependencies: dependencies)
        await model.translate(english, source: .typed)
        return try #require(model.result)
    }

    @Test func translatingOpensTheResultAndCountsAgainstTheFreeLimit() async throws {
        let model = NewPhraseModel(dependencies: dependencies)
        await model.translate("  How much?  ", source: .spoken)

        let result = try #require(model.result)
        #expect(result.english == "How much?")
        #expect(result.source == .spoken)
        #expect(dependencies.usage.translationsRemainingToday == 2)
    }

    @Test func emptyInputDoesNothing() async {
        let model = NewPhraseModel(dependencies: dependencies)
        await model.translate("   ", source: .typed)
        #expect(model.result == nil)
        #expect(dependencies.usage.translationsRemainingToday == 3)
    }

    @Test func reachingTheLimitOpensThePaywallAndKeepsThePhrase() async {
        for _ in 0 ..< 3 {
            dependencies.usage.recordTranslation()
        }
        let model = NewPhraseModel(dependencies: dependencies)
        await model.translate("Where's the station?", source: .typed)

        #expect(model.result == nil)
        #expect(model.showsPaywall)
        #expect(model.pendingEnglish == "Where's the station?")
    }

    @Test func savingStoresAFullPhraseAsANewCard() async throws {
        let result = try await translated()
        result.save()
        #expect(result.saveState == .saved)

        let saved = try dependencies.phrases.phrases(in: "zh-CN", section: .userPhrases, sort: .newest)
        let phrase = try #require(saved.first)
        #expect(phrase.englishText == "Let's take a taxi")
        #expect(phrase.targetText == result.current.targetText)
        #expect(phrase.phraseSource == .typed)
        #expect(phrase.stableID != nil)
        #expect(!phrase.gloss.isEmpty)
        #expect(phrase.cardState.phase == .new)
        #expect(phrase.promptVersion == "fake")
    }

    @Test func clarifyingReplacesTheTranslationAndCanGoBack() async throws {
        let result = try await translated()
        let original = result.current

        let clarify = ClarifyModel(result: result, dependencies: dependencies)
        clarify.mode = .type
        clarify.typedText = "it was something like dai cha"
        await clarify.send()

        guard case let .reply(reply) = clarify.phase else {
            Issue.record("Expected a reply, got \(clarify.phase)")
            return
        }
        let candidate = try #require(reply.candidates.first)
        clarify.use(candidate)

        #expect(result.current == candidate)
        #expect(result.clarifications.map(\.text) == ["it was something like dai cha"])
        #expect(result.clarifications.first?.previousTargetText == original.targetText)
        #expect(result.clarificationsRemaining == 2)

        result.backToPreviousVersion()
        #expect(result.current == original)
        #expect(!result.canGoBack)
    }

    @Test func clarificationHistoryIsSentWithTheNextRound() async throws {
        let result = try await translated()
        result.apply(result.current, clarification: "more informal")
        #expect(result.clarificationHistory == [ClarificationTurn(clarification: "more informal", targetText: result.previousVersions[0].targetText)])
    }

    @Test func freeUsersCanClarifyThreeTimesPerPhrase() async throws {
        let result = try await translated()
        let clarify = ClarifyModel(result: result, dependencies: dependencies)
        clarify.mode = .type
        for _ in 0 ..< 3 {
            clarify.typedText = "shorter"
            await clarify.send()
            clarify.tryAgain()
        }
        clarify.typedText = "shorter again"
        #expect(clarify.isLimitReached)
        #expect(!clarify.canSend)
    }

    @Test func retryKeepsThePreviousVersion() async throws {
        let result = try await translated()
        await result.retry()
        #expect(result.canGoBack)
        #expect(result.retryError == nil)
    }
}
