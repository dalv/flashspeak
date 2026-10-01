import Foundation

/// FSRS-5 with its published default parameters and 90% desired retention,
/// driven by two ratings (Hard = Again, Easy = Good).
///
/// Learning works in short steps: a failed new card returns after 1 minute,
/// a lapsed review card after 10 minutes, and passing either moves it to
/// review with a whole-day interval. Pure: `now` is always passed in.
struct FSRSScheduler: Scheduler {
    let version = "fsrs-5-default"

    /// FSRS-5 default weights w0…w18.
    private let w: [Double] = [
        0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046, 1.54575, 0.1192,
        1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315, 2.9898, 0.51655, 0.6621,
    ]
    private let desiredRetention = 0.9
    private let decay = -0.5
    private var factor: Double {
        pow(0.9, 1 / decay) - 1
    } // 19/81

    private let learningStep: TimeInterval = 60
    private let relearningStep: TimeInterval = 10 * 60
    private let maximumIntervalDays = 36500.0

    func next(_ state: CardState, rating: ReviewRating, now: Date) -> CardState {
        let grade = rating.fsrsGrade
        var next = state
        next.lastReview = now

        switch state.phase {
        case .new:
            next.stability = initialStability(grade)
            next.difficulty = initialDifficulty(grade)
            if rating == .hard {
                next.phase = .learning
                next.due = now.addingTimeInterval(learningStep)
            } else {
                next.phase = .review
                next.due = dueDate(stability: next.stability, from: now)
            }

        case .learning, .relearning:
            next.difficulty = nextDifficulty(state.difficulty, grade: grade)
            if isSameDay(state.lastReview, now) {
                next.stability = shortTermStability(state.stability, grade: grade)
            } else {
                let r = retrievability(daysSince: elapsedDays(state.lastReview, now), stability: state.stability)
                next.stability = rating == .hard
                    ? forgetStability(state, retrievability: r)
                    : recallStability(state, retrievability: r, grade: grade)
            }
            if rating == .hard {
                next.due = now.addingTimeInterval(state.phase == .learning ? learningStep : relearningStep)
            } else {
                next.phase = .review
                next.due = dueDate(stability: next.stability, from: now)
            }

        case .review:
            let r = retrievability(daysSince: elapsedDays(state.lastReview, now), stability: state.stability)
            next.difficulty = nextDifficulty(state.difficulty, grade: grade)
            if rating == .hard {
                next.phase = .relearning
                next.lapses += 1
                next.stability = forgetStability(state, retrievability: r)
                next.due = now.addingTimeInterval(relearningStep)
            } else {
                next.stability = recallStability(state, retrievability: r, grade: grade)
                next.due = dueDate(stability: next.stability, from: now)
            }
        }
        return next
    }

    /// The interval, in whole days, that a stability gives at the desired retention.
    func intervalDays(stability: Double) -> Double {
        let raw = stability / factor * (pow(desiredRetention, 1 / decay) - 1)
        return min(max(raw.rounded(), 1), maximumIntervalDays)
    }

    // MARK: - FSRS-5 formulas

    private func retrievability(daysSince t: Double, stability s: Double) -> Double {
        guard s > 0 else { return 0 }
        return pow(1 + factor * t / s, decay)
    }

    private func initialStability(_ g: Double) -> Double {
        max(w[Int(g) - 1], 0.1)
    }

    private func initialDifficulty(_ g: Double) -> Double {
        clampDifficulty(w[4] - exp(w[5] * (g - 1)) + 1)
    }

    private func nextDifficulty(_ d: Double, grade g: Double) -> Double {
        let delta = -w[6] * (g - 3)
        let damped = d + delta * (10 - d) / 9
        let reverted = w[7] * initialDifficulty(4) + (1 - w[7]) * damped
        return clampDifficulty(reverted)
    }

    private func recallStability(_ state: CardState, retrievability r: Double, grade g: Double) -> Double {
        let s = state.stability, d = state.difficulty
        let hardPenalty = g == 2 ? w[15] : 1
        let easyBonus = g == 4 ? w[16] : 1
        let increase = exp(w[8]) * (11 - d) * pow(s, -w[9]) * (exp(w[10] * (1 - r)) - 1) * hardPenalty * easyBonus
        return s * (increase + 1)
    }

    private func forgetStability(_ state: CardState, retrievability r: Double) -> Double {
        let s = state.stability, d = state.difficulty
        let forgotten = w[11] * pow(d, -w[12]) * (pow(s + 1, w[13]) - 1) * exp(w[14] * (1 - r))
        return max(min(forgotten, s / exp(w[17] * w[18])), 0.1)
    }

    private func shortTermStability(_ s: Double, grade g: Double) -> Double {
        max(s * exp(w[17] * (g - 3 + w[18])), 0.1)
    }

    private func clampDifficulty(_ d: Double) -> Double {
        min(max(d, 1), 10)
    }

    // MARK: - Dates

    private func dueDate(stability: Double, from now: Date) -> Date {
        now.addingTimeInterval(intervalDays(stability: stability) * 86400)
    }

    private func elapsedDays(_ last: Date?, _ now: Date) -> Double {
        guard let last else { return 0 }
        return max(now.timeIntervalSince(last) / 86400, 0)
    }

    private func isSameDay(_ last: Date?, _ now: Date) -> Bool {
        guard let last else { return true }
        return now.timeIntervalSince(last) < 86400
    }
}
