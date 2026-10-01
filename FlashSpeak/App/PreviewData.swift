import Foundation
import SwiftData

/// Sample phrases in all four languages for Previews, built from the
/// design system's `SampleContent`, plus a few preset items.
@MainActor
enum PreviewData {
    static func seed(_ context: ModelContext) {
        let now = Date()
        for (languageIndex, language) in SampleContent.languages.enumerated() {
            for (index, content) in language.phrases.enumerated() {
                let phrase = Phrase(
                    englishText: content.english,
                    targetText: content.native,
                    pronunciation: content.romanization ?? "",
                    languageCode: language.theme.id
                )
                phrase.stableID = UUID()
                phrase.source = (index.isMultiple(of: 2) ? PhraseSource.spoken : .typed).rawValue
                phrase.reading = content.reading
                phrase.level = content.level.flatMap { Int($0.filter(\.isNumber)) } ?? 1
                phrase.createdAt = now.addingTimeInterval(-Double(languageIndex * 10 + index) * 3600)
                phrase.fsrsState = index == 0 ? CardState.Phase.new.rawValue : CardState.Phase.review.rawValue
                phrase.nextReviewAt = now.addingTimeInterval(index.isMultiple(of: 2) ? -3600 : 86400)
                context.insert(phrase)
            }
        }
        try? context.save()
    }
}
