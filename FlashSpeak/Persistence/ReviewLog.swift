import Foundation
import SwiftData

/// One review of a phrase. Append-only: inserted, never edited, so offline
/// reviews on two devices never overwrite each other. The phrase's FSRS
/// fields are a cache that can be rebuilt from these.
@Model
final class ReviewLog {
    var stableID: UUID?
    var phrase: Phrase?
    var reviewedAt: Date = Date()
    /// A `ReviewRating` raw value.
    var rating: Int = 0
    /// A `ReviewMode` raw value.
    var mode: String = ReviewMode.flashcard.rawValue
    var stateAfter: Int?
    var stabilityAfter: Double?
    var difficultyAfter: Double?
    var dueAfter: Date?
    var schedulerVersion: String?

    init(phrase: Phrase, rating: ReviewRating, mode: ReviewMode, after: CardState, schedulerVersion: String, at date: Date) {
        stableID = UUID()
        self.phrase = phrase
        reviewedAt = date
        self.rating = rating.rawValue
        self.mode = mode.rawValue
        stateAfter = after.phase.rawValue
        stabilityAfter = after.stability
        difficultyAfter = after.difficulty
        dueAfter = after.due
        self.schedulerVersion = schedulerVersion
    }
}
