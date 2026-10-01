@testable import FlashSpeak
import Foundation
import Testing

struct FSRSSchedulerTests {
    let scheduler = FSRSScheduler()
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func days(_ n: Double) -> TimeInterval {
        n * 86400
    }

    @Test func newCardRatedEasyGoesToReviewInThreeDays() {
        let next = scheduler.next(.new(due: start), rating: .easy, now: start)
        #expect(next.phase == .review)
        #expect(next.due == start.addingTimeInterval(days(3)))
        #expect(next.lastReview == start)
        #expect(next.lapses == 0)
    }

    @Test func newCardRatedHardComesBackInOneMinute() {
        let next = scheduler.next(.new(due: start), rating: .hard, now: start)
        #expect(next.phase == .learning)
        #expect(next.due == start.addingTimeInterval(60))
    }

    @Test func learningCardRatedEasyGraduatesToAtLeastOneDay() {
        let learning = scheduler.next(.new(due: start), rating: .hard, now: start)
        let later = start.addingTimeInterval(60)
        let next = scheduler.next(learning, rating: .easy, now: later)
        #expect(next.phase == .review)
        #expect(next.due >= later.addingTimeInterval(days(1)))
    }

    @Test func passingAReviewOnTimeGrowsStability() {
        let first = scheduler.next(.new(due: start), rating: .easy, now: start)
        let second = scheduler.next(first, rating: .easy, now: first.due)
        #expect(second.phase == .review)
        #expect(second.stability > first.stability)
        #expect(second.due.timeIntervalSince(first.due) > first.due.timeIntervalSince(start))
    }

    @Test func failingAReviewLapsesAndRelearnsInTenMinutes() {
        let reviewed = scheduler.next(.new(due: start), rating: .easy, now: start)
        let next = scheduler.next(reviewed, rating: .hard, now: reviewed.due)
        #expect(next.phase == .relearning)
        #expect(next.lapses == 1)
        #expect(next.stability < reviewed.stability)
        #expect(next.due == reviewed.due.addingTimeInterval(600))
    }

    @Test func difficultyStaysWithinBounds() {
        var state = CardState.new(due: start)
        var now = start
        for _ in 0 ..< 30 {
            state = scheduler.next(state, rating: .hard, now: now)
            now = state.due
        }
        #expect((1 ... 10).contains(state.difficulty))
        for _ in 0 ..< 30 {
            state = scheduler.next(state, rating: .easy, now: now)
            now = state.due
        }
        #expect((1 ... 10).contains(state.difficulty))
    }

    @Test func sameInputsGiveSameOutput() {
        let a = scheduler.next(.new(due: start), rating: .easy, now: start)
        let b = scheduler.next(.new(due: start), rating: .easy, now: start)
        #expect(a == b)
    }

    @Test func intervalEqualsStabilityAtNinetyPercentRetention() {
        #expect(scheduler.intervalDays(stability: 10) == 10)
        #expect(scheduler.intervalDays(stability: 0.2) == 1)
    }
}
