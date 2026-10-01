/// Finds an exact duplicate among existing phrases.
///
/// A phrase is a duplicate if its normalized English or its normalized
/// translation matches an existing one: two English wordings with the same
/// translation would make the same card.
enum ExactDuplicateMatcher {
    struct Candidate: Sendable {
        let english: String
        let target: String
    }

    /// The index of the first matching candidate, or nil.
    static func firstMatch(english: String, target: String?, in candidates: [Candidate]) -> Int? {
        let englishKey = PhraseNormalizer.normalize(english)
        let targetKey = target.map(PhraseNormalizer.normalize) ?? ""

        return candidates.firstIndex { candidate in
            if !englishKey.isEmpty, PhraseNormalizer.normalize(candidate.english) == englishKey {
                return true
            }
            return !targetKey.isEmpty && PhraseNormalizer.normalize(candidate.target) == targetKey
        }
    }
}
