/// One word or chunk of the word-by-word gloss.
struct GlossPair: Codable, Hashable, Sendable {
    /// The target-language word, in native script.
    var target: String
    /// Its romanization, if the language has one.
    var romanization: String?
    /// The English meaning.
    var english: String
}
