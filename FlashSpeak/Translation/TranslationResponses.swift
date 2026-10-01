/// The reply to a clarification.
struct ClarificationResult: Codable, Hashable, Sendable {
    /// One line: what changed, or what the user was probably thinking of.
    var explanation: String
    /// True when the clarification suggests the current translation is right.
    var keepsCurrent: Bool
    /// One to three candidates; empty when `keepsCurrent` is true.
    var candidates: [TranslationResult]
}

/// One suggested phrase with its translation.
struct SuggestedPhrase: Codable, Hashable, Sendable {
    var english: String
    var translation: TranslationResult
}
