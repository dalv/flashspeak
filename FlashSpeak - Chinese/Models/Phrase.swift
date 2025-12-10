import Foundation
import SwiftData

@Model
final class Phrase {
    var id: UUID
    var englishText: String
    var hanzi: String
    var pinyin: String
    var literalTranslation: String
    var createdAt: Date
    var lastReviewedAt: Date?
    var nextReviewAt: Date
    var easeFactor: Double
    var interval: Double // in days
    var repetitions: Int
    
    init(
        englishText: String,
        hanzi: String,
        pinyin: String,
        literalTranslation: String = ""
    ) {
        self.id = UUID()
        self.englishText = englishText
        self.hanzi = hanzi
        self.pinyin = pinyin
        self.literalTranslation = literalTranslation
        self.createdAt = Date()
        self.lastReviewedAt = nil
        self.nextReviewAt = Date()
        self.easeFactor = 2.5
        self.interval = 0
        self.repetitions = 0
    }
}
