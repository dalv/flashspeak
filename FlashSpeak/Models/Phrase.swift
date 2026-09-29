import Foundation
import SwiftData

@Model
final class Phrase {
    var englishText: String = ""
    var targetText: String = ""
    var pronunciation: String = ""
    var literalTranslation: String = ""
    var languageCode: String = "zh-CN"
    var createdAt: Date = Date()
    var lastReviewedAt: Date?
    var nextReviewAt: Date = Date()
    var easeFactor: Double = 2.5
    var interval: Double = 0
    var repetitions: Int = 0

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
        self.createdAt = Date()
        self.lastReviewedAt = nil
        self.nextReviewAt = Date()
        self.easeFactor = 2.5
        self.interval = 0
        self.repetitions = 0
    }
}
