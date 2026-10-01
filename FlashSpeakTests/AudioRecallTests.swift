@testable import FlashSpeak
import Foundation
import SwiftData
import Testing

@MainActor
struct AudioRecallTests {
    let dependencies = AppDependencies.test()
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    @discardableResult
    private func add(
        _ english: String,
        phase: CardState.Phase = .new,
        due: TimeInterval = 86400,
        created: TimeInterval = -30 * 86400,
        hidden: Bool = false
    ) throws -> Phrase {
        let phrase = Phrase(englishText: english, targetText: "[\(english)]", languageCode: "zh-CN")
        phrase.fsrsState = phase.rawValue
        phrase.nextReviewAt = now.addingTimeInterval(due)
        phrase.createdAt = now.addingTimeInterval(created)
        phrase.hiddenFromReview = hidden
        try dependencies.phrases.insert(phrase)
        return phrase
    }

    private var speech: FakeSpeechSynthesizer {
        dependencies.speech as! FakeSpeechSynthesizer
    }

    private var controls: FakeRecallSystemControls {
        dependencies.recallControls as! FakeRecallSystemControls
    }

    /// Lets the session's task run until `condition` holds.
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0 ..< 1000 where !condition() {
            await Task.yield()
        }
    }

    private func session(sleep: @escaping RecallSession.Sleep = { _ in }) -> RecallSession {
        dependencies.settings.currentLanguageCode = "zh-CN"
        let model = AudioRecallModel(dependencies: dependencies)
        model.refresh()
        model.start(now: now, sleep: sleep)
        return model.session!
    }

    // MARK: Queue

    @Test func queueOrdersDueThenRecentThenTheRest() throws {
        let older = try add("older")
        let recent = try add("recent", created: -86400)
        let newest = try add("newest", created: -60)
        let overdue = try add("overdue", phase: .review, due: -7200)
        let due = try add("due", phase: .review, due: -60)
        let hidden = try add("hidden", phase: .review, due: -9000, hidden: true)

        let queue = RecallQueue.make(
            from: [older, recent, newest, overdue, due, hidden],
            length: .all,
            now: now,
            shuffle: { $0 }
        )
        #expect(queue.map(\.englishText) == ["overdue", "due", "newest", "recent", "older"])
    }

    @Test func queueRespectsTheSessionLength() throws {
        let phrases = try (0 ..< 25).map { try add("p\($0)") }
        #expect(RecallQueue.make(from: phrases, length: .ten, now: now).count == 10)
        #expect(RecallQueue.make(from: phrases, length: .twenty, now: now).count == 20)
        #expect(RecallQueue.make(from: phrases, length: .all, now: now).count == 25)
    }

    // MARK: Session

    @Test func aSessionPlaysEnglishThenTheAnswerAndNeverSchedules() async throws {
        let first = try add("Turn left")
        try add("No spicy, please")
        let dueBefore = first.nextReviewAt

        let session = session()
        await waitUntil { session.isFinished }

        #expect(session.isFinished)
        #expect(session.practisedCount == 2)
        // Older phrases play in random order; each English is followed by its answer.
        let texts = speech.spoken.map(\.text)
        #expect(texts.count == 4)
        #expect(texts[1] == "[\(texts[0])]")
        #expect(texts[3] == "[\(texts[2])]")
        #expect(speech.spoken.filter { $0.role == .english }.count == 2)
        #expect(speech.spoken.filter { $0.role != .english }.allSatisfy { $0.speed == .slow })
        #expect(first.reviews?.isEmpty ?? true)
        #expect(first.nextReviewAt == dueBefore)
        #expect(controls.isActive == false)
    }

    @Test func playTwiceRepeatsTheTranslation() async throws {
        try add("Turn left")
        dependencies.settings.playTranslationTwice = true
        let session = session()
        await waitUntil { session.isFinished }
        #expect(speech.spoken.map(\.text) == ["Turn left", "[Turn left]", "[Turn left]"])
    }

    @Test func pauseStopsAndSkipMovesOn() async throws {
        try add("first", created: -60)
        try add("second", created: -120)
        // Sleeps never end on their own, so the session waits in the thinking gap.
        let session = session(sleep: { _ in try await Task.sleep(for: .seconds(3600)) })
        await waitUntil { session.phase == .thinking(dots: 1) }
        #expect(session.current?.englishText == "first")

        session.pause()
        #expect(session.isPaused)
        #expect(controls.lastUpdate?.isPlaying == false)

        session.skip()
        #expect(session.current?.englishText == "second")
        #expect(session.phase == .english)
        #expect(session.isPaused)
        #expect(session.practisedCount == 0)

        session.skip()
        #expect(session.isFinished)
    }

    @Test func interruptionsPauseAndResume() async throws {
        try add("first")
        let session = session(sleep: { _ in try await Task.sleep(for: .seconds(3600)) })
        await waitUntil { session.phase == .thinking(dots: 1) }

        controls.send(.interruptionBegan)
        #expect(session.isPaused)
        controls.send(.interruptionEnded(shouldResume: true))
        #expect(!session.isPaused)

        controls.send(.outputDisconnected)
        #expect(session.isPaused)
        // Unplugging headphones doesn't resume on its own.
        controls.send(.interruptionEnded(shouldResume: true))
        #expect(session.isPaused)

        controls.send(.next)
        #expect(session.isFinished)
    }

    @Test func anEmptySectionFinishesAtOnce() {
        let session = session()
        #expect(session.isFinished)
        #expect(session.practisedCount == 0)
    }
}
