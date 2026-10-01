import Foundation
import NaturalLanguage

/// Sentence embeddings for near-duplicate detection.
protocol EmbeddingProvider: Sendable {
    func embedding(for text: String) -> [Double]?
}

/// Apple's on-device English sentence embedding (NaturalLanguage).
struct NLSentenceEmbeddingProvider: EmbeddingProvider {
    func embedding(for text: String) -> [Double]? {
        NLEmbedding.sentenceEmbedding(for: .english)?.vector(for: text.lowercased())
    }
}

/// Stores embeddings compactly on `Phrase.embedding` (Float32).
enum EmbeddingCoding {
    static func encode(_ vector: [Double]) -> Data {
        vector.map(Float.init).withUnsafeBufferPointer { Data(buffer: $0) }
    }

    static func decode(_ data: Data) -> [Double] {
        data.withUnsafeBytes { raw in
            raw.bindMemory(to: Float.self).map(Double.init)
        }
    }
}
