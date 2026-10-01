/// A part of a language's library.
enum PhraseSection: Hashable, Sendable {
    /// User phrases plus every preset item in the store (started categories).
    case all
    /// Spoken, typed and saved suggested phrases.
    case userPhrases
    /// One preset category, by ID.
    case preset(String)
}
