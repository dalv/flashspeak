import SwiftData

/// Appends reviews. Reviews are never edited or deleted.
@MainActor
protocol ReviewRepository {
    func append(_ review: ReviewLog) throws
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
}
