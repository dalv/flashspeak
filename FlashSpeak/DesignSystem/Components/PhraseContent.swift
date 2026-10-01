import Foundation

/// The text of a phrase as phrase components show it.
///
/// Plain values, so the design system doesn't depend on the `Phrase`
/// model. Features map their model to this.
struct PhraseContent: Identifiable, Hashable, Sendable {
    var id: String {
        english + native
    }

    let english: String
    /// The translation in its own script.
    let native: String
    /// Kana reading, for Japanese only.
    var reading: String?
    /// Pinyin, romaji or revised romanization. Nil for Indonesian.
    var romanization: String?
    /// Level in the language's own scale, e.g. "HSK 2", "JLPT N4", "TOPIK 1", "A2".
    var level: String?
}
