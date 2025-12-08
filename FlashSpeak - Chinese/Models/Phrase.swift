import Foundation
import SwiftData

@Model
final class Phrase {
    var id: UUID
    var englishText: String
    var hanzi: String
    var pinyin: String
    var createdAt: Date
    var lastReviewedAt: Date?
    var nextReviewAt: Date
    var easeFactor: Double
    var interval: Double // in days
    var repetitions: Int
    
    init(
        englishText: String,
        hanzi: String,
        pinyin: String
    ) {
        self.id = UUID()
        self.englishText = englishText
        self.hanzi = hanzi
        self.pinyin = pinyin
        self.createdAt = Date()
        self.lastReviewedAt = nil
        self.nextReviewAt = Date() // due immediately for first review
        self.easeFactor = 2.5 // SM-2 default
        self.interval = 0
        self.repetitions = 0
    }
}
