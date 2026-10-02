import Foundation

/// Picks and orders the phrases for an audio recall session (PRD, Audio
/// recall): a random order each session, cut to the session length.
enum RecallQueue {
    static func make(
        from phrases: [Phrase],
        length: RecallSessionLength,
        shuffle: ([Phrase]) -> [Phrase] = { $0.shuffled() }
    ) -> [Phrase] {
        let ordered = shuffle(phrases.filter { !$0.hiddenFromReview && !$0.excludedFromRecall })
        guard let limit = length.limit else { return ordered }
        return Array(ordered.prefix(limit))
    }
}
