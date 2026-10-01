import Foundation
import SwiftData

/// Appends reviews. Reviews are never edited or deleted.
@MainActor
protocol ReviewRepository {
    func append(_ review: ReviewLog) throws
    /// How many phrases in a language had their first-ever review at or
    /// after `since`, so the daily new-card limit counts cards already
    /// introduced today.
    func newCardsIntroduced(in languageCode: String, since: Date) throws -> Int
}

@MainActor
final class SwiftDataReviewRepository: ReviewRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func append(_ review: ReviewLog) throws {
        context.insert(review)
        try context.save()
    }

    func newCardsIntroduced(in languageCode: String, since: Date) throws -> Int {
        let descriptor = FetchDescriptor<ReviewLog>(predicate: #Predicate { $0.reviewedAt >= since })
        let phrases = try context.fetch(descriptor)
            .compactMap(\.phrase)
            .filter { $0.languageCode == languageCode }
        let distinct = Dictionary(phrases.map { (ObjectIdentifier($0), $0) }, uniquingKeysWith: { first, _ in first })
        return distinct.values.count { phrase in
            !(phrase.reviews ?? []).contains { $0.reviewedAt < since }
        }
    }
}
