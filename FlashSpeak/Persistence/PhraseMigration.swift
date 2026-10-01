import Foundation

/// Brings phrases from the 1.x app up to the overhaul schema. Pure apart
/// from mutating the phrases passed in; run once at launch by
/// `MigrationRunner` and safe to run again (it skips migrated phrases).
enum PhraseMigration {
    /// Bump when a new migration step is added.
    static let version = 1

    /// FSRS difficulty given to legacy cards: the default for a "Good" first rating.
    static let legacyDifficulty = 5.0

    /// - Returns: how many phrases changed.
    @discardableResult
    static func migrate(_ phrases: [Phrase], makeID: () -> UUID = UUID.init) -> Int {
        var changed = 0
        for phrase in phrases where phrase.stableID == nil {
            phrase.stableID = makeID()
            phrase.updatedAt = phrase.updatedAt ?? phrase.createdAt
            // `source` already defaults to legacy for 1.x rows.
            if phrase.fsrsState == nil {
                seedSchedule(phrase)
            }
            changed += 1
        }
        return changed
    }

    /// Seeds FSRS from the SM-2 fields. There is no review history, so a
    /// reviewed card starts in review with its SM-2 interval as stability
    /// and keeps its due date; an unreviewed card starts new.
    private static func seedSchedule(_ phrase: Phrase) {
        if phrase.repetitions > 0 {
            phrase.fsrsState = CardState.Phase.review.rawValue
            phrase.fsrsStability = max(phrase.interval, 1)
            phrase.fsrsDifficulty = legacyDifficulty
        } else {
            phrase.fsrsState = CardState.Phase.new.rawValue
            phrase.fsrsStability = 0
            phrase.fsrsDifficulty = 0
        }
        phrase.fsrsLapses = 0
    }
}
