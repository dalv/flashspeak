import Foundation

/// Reads and writes phrases. Every query excludes soft-deleted phrases and
/// languages outside `Language.supported`.
@MainActor
protocol PhraseRepository {
    func phrases(in languageCode: String, section: PhraseSection, sort: PhraseSort) throws -> [Phrase]
    /// Cards to review now: due cards first (most overdue first), then up
    /// to `newLimit` new cards (oldest first). Hidden items are left out.
    func due(in languageCode: String, section: PhraseSection, now: Date, newLimit: Int) throws -> [Phrase]
    func insert(_ phrase: Phrase) throws
    func softDelete(_ phrase: Phrase, at date: Date) throws
    func purgeDeleted(olderThan date: Date) throws
    func save() throws
}
