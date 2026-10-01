/// Where a phrase came from. Stored as its raw value in `Phrase.source`.
enum PhraseSource: String, Codable, Sendable, CaseIterable {
    case spoken
    case typed
    case suggested
    case imported
    case preset
    /// Created by the 1.x app, before sources were recorded.
    case legacy
}
