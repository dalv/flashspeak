/// `POST /v2/translate`
struct TranslationRequest: Codable, Hashable, Sendable {
    var english: String
    /// Language code, e.g. "zh-CN".
    var language: String
    var register: Register
}

/// One earlier round of clarification for the same phrase.
struct ClarificationTurn: Codable, Hashable, Sendable {
    var clarification: String
    /// The translation that clarification produced.
    var targetText: String
}

/// `POST /v2/clarify`
struct ClarificationRequest: Codable, Hashable, Sendable {
    var english: String
    var language: String
    var register: Register
    /// The translation on screen now.
    var currentTargetText: String
    var currentRomanization: String?
    /// Earlier rounds, oldest first.
    var history: [ClarificationTurn]
    /// What the user said or typed, e.g. "it was something like dai cha".
    var clarification: String
}

/// `POST /v2/suggest`
struct SuggestionRequest: Codable, Hashable, Sendable {
    var language: String
    /// A situation, e.g. "At a café or restaurant", or the user's own text.
    var category: String
    /// The set's level, 1–6.
    var level: Int
    var register: Register
    /// English of phrases already in the set, to avoid repeats.
    var existing: [String]
    var count: Int
}

/// `POST /v2/flag`
struct TranslationFlag: Codable, Hashable, Sendable {
    var english: String
    var language: String
    var targetText: String
    var promptVersion: String?
    var clarifications: [String]
    var note: String?
}
