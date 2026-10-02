import Foundation

/// Picks and orders the phrases for an audio recall session (PRD, Audio
/// recall): due cards first (most overdue first), then phrases added in
/// the last week (newest first), then the rest in random order.
enum RecallQueue {
    static let recentWindow: TimeInterval = 7 * 86400

    static func make(
        from phrases: [Phrase],
        length: RecallSessionLength,
        now: Date,
        shuffle: ([Phrase]) -> [Phrase] = { $0.shuffled() }
    ) -> [Phrase] {
        let candidates = phrases.filter { !$0.hiddenFromReview && !$0.excludedFromRecall }
        let isDue: (Phrase) -> Bool = { phrase in
            let scheduled = (phrase.fsrsState ?? 0) != CardState.Phase.new.rawValue
            return scheduled && phrase.nextReviewAt <= now
        }

        let due = candidates.filter(isDue).sorted { $0.nextReviewAt < $1.nextReviewAt }
        let rest = candidates.filter { !isDue($0) }
        let recent = rest
            .filter { now.timeIntervalSince($0.createdAt) <= recentWindow }
            .sorted { $0.createdAt > $1.createdAt }
        let older = shuffle(rest.filter { now.timeIntervalSince($0.createdAt) > recentWindow })

        let ordered = due + recent + older
        guard let limit = length.limit else { return ordered }
        return Array(ordered.prefix(limit))
    }
}
