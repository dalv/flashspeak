import Foundation

/// Finds exact and near duplicates of a phrase among a set's phrases.
///
/// Exact: `ExactDuplicateMatcher` on English or translation. Near: cosine
/// distance between English sentence embeddings below `nearThreshold`.
/// The threshold was set from measured NLEmbedding distances (2026-10-01):
/// "How much is this?" / "How much does this cost?" 0.52,
/// "Can you say that again slowly?" / "Could you repeat that more slowly?" 0.59,
/// "An iced Americano, please" / "A hot latte, please" 0.67 (not a duplicate),
/// "Turn left" / "Turn right" 0.79. Near matches only ask "Save anyway?",
/// so a miss or a false alarm is cheap.
struct DuplicateDetector {
    static let nearThreshold = 0.62

    let embeddings: any EmbeddingProvider

    func check(english: String, target: String?, among phrases: [Phrase]) -> DuplicateCheck {
        let candidates = phrases.map { ExactDuplicateMatcher.Candidate(english: $0.englishText, target: $0.targetText) }
        if let index = ExactDuplicateMatcher.firstMatch(english: english, target: target, in: candidates) {
            return .exact(phrases[index])
        }
        guard let vector = embeddings.embedding(for: english) else { return .none }

        var best: (phrase: Phrase, distance: Double)?
        for phrase in phrases {
            guard let other = storedOrComputed(phrase) else { continue }
            let distance = Self.cosineDistance(vector, other)
            if distance < Self.nearThreshold, distance < (best?.distance ?? .infinity) {
                best = (phrase, distance)
            }
        }
        return best.map { .near($0.phrase) } ?? .none
    }

    /// Uses the embedding saved on the phrase; computes it for older phrases.
    private func storedOrComputed(_ phrase: Phrase) -> [Double]? {
        if let data = phrase.embedding {
            return EmbeddingCoding.decode(data)
        }
        return embeddings.embedding(for: phrase.englishText)
    }

    static func cosineDistance(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return .infinity }
        var dot = 0.0, normA = 0.0, normB = 0.0
        for i in a.indices {
            dot += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        guard normA > 0, normB > 0 else { return .infinity }
        return 1 - dot / (normA.squareRoot() * normB.squareRoot())
    }
}
