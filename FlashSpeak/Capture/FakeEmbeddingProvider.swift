/// Embeddings for tests and Previews: fixed vectors for known phrases, so
/// near-duplicate behaviour is deterministic.
struct FakeEmbeddingProvider: EmbeddingProvider {
    var vectors: [String: [Double]] = [:]

    func embedding(for text: String) -> [Double]? {
        vectors[text.lowercased()]
    }
}
