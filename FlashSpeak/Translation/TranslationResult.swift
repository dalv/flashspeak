/// One translation as the Worker returns it (v2).
struct TranslationResult: Codable, Hashable, Sendable {
    /// Native script.
    var targetText: String
    /// Pinyin, romaji or Revised Romanization; nil for Indonesian.
    var romanization: String?
    /// Kana reading, Japanese only.
    var reading: String?
    var gloss: [GlossPair]
    var literal: String
    var alternative: String?
    var usageNote: String?
    /// Internal level 1–6.
    var level: Int?
    var promptVersion: String
}
