import Foundation
import SwiftData

/// One phrase in a language set.
///
/// CloudKit rules: every property is optional or defaulted, nothing is
/// unique, and the schema is additive only. Never rename or remove a
/// property; legacy fields stay even when unused (see architecture.md).
@Model
final class Phrase {
    // MARK: Legacy fields (1.x)

    var englishText: String = ""
    /// Translation in native script.
    var targetText: String = ""
    /// Romanization (pinyin, romaji, Revised Romanization). Empty for Indonesian.
    var pronunciation: String = ""
    /// Plain-text literal gloss.
    var literalTranslation: String = ""
    var languageCode: String = "zh-CN"
    var createdAt: Date = Date()
    var lastReviewedAt: Date?
    /// The FSRS due date (was the SM-2 due date).
    var nextReviewAt: Date = Date()
    /// SM-2, no longer written. Read once by `PhraseMigration`.
    var easeFactor: Double = 2.5
    /// SM-2 interval in days, no longer written.
    var interval: Double = 0
    /// SM-2, no longer written.
    var repetitions: Int = 0

    // MARK: Overhaul fields (all additive)

    /// Stable ID for sync and a future backend. Backfilled by the migration.
    /// Named `stableID`, not `id`, so it doesn't replace SwiftData's identity.
    var stableID: UUID?
    /// A `PhraseSource` raw value.
    var source: String = PhraseSource.legacy.rawValue
    /// Kana reading, Japanese only.
    var reading: String?
    /// JSON `[GlossPair]` for the expandable word-by-word gloss.
    var glossData: Data?
    var alternative: String?
    var usageNote: String?
    /// Internal level 1–6.
    var level: Int?
    /// Sentence embedding for near-duplicate checks.
    var embedding: Data?
    var promptVersion: String?
    var updatedAt: Date?
    /// Soft delete; purged after 30 days.
    var deletedAt: Date?

    /// A `CardState.Phase` raw value; nil means never scheduled by FSRS.
    var fsrsState: Int?
    var fsrsStability: Double?
    var fsrsDifficulty: Double?
    var fsrsLapses: Int = 0
    var schedulerVersion: String?

    @Relationship(deleteRule: .nullify, inverse: \ReviewLog.phrase)
    var reviews: [ReviewLog]?

    /// Preset category ID ("numbers"); nil for user phrases.
    var presetCategory: String?
    /// Stable key of the item within its category ("12", "monday").
    var presetItemKey: String?
    var presetContentVersion: Int?
    /// JSON `[Clarification]`, oldest first.
    var clarificationsData: Data?
    /// Hidden from review without deleting (preset items).
    var hiddenFromReview: Bool = false
    /// Out of flashcards. False for user phrases; preset cards start true
    /// and are cleared when their category is added to flashcards.
    var excludedFromFlashcards: Bool = false
    /// Out of audio recall, the same way.
    var excludedFromRecall: Bool = false

    init(
        englishText: String,
        targetText: String,
        pronunciation: String = "",
        literalTranslation: String = "",
        languageCode: String = "zh-CN"
    ) {
        self.englishText = englishText
        self.targetText = targetText
        self.pronunciation = pronunciation
        self.literalTranslation = literalTranslation
        self.languageCode = languageCode
        createdAt = Date()
        lastReviewedAt = nil
        nextReviewAt = Date()
        easeFactor = 2.5
        interval = 0
        repetitions = 0
    }
}
