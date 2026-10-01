/// The bundled preset content for one language, as written by
/// `cloudflare-worker/scripts/generate-presets.mjs`.
struct PresetFile: Decodable, Sendable {
    let language: String
    /// Bumped when corrected content ships; existing cards update in place.
    let contentVersion: Int
    /// False until a native reviewer has checked it (decision 0018).
    let reviewed: Bool
    let categories: [PresetCategoryContent]
}

/// One category's items in one language.
struct PresetCategoryContent: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let items: [PresetItem]

    var kind: PresetCategoryKind? {
        PresetCategoryKind(rawValue: id)
    }

    var title: String {
        kind?.title ?? id.capitalized
    }
}

/// One card. `key` is stable across content versions.
struct PresetItem: Decodable, Identifiable, Hashable, Sendable {
    let key: String
    /// The front of the card: English, or digits for numbers.
    let english: String
    let targetText: String
    let romanization: String?
    let reading: String?
    let gloss: [GlossPair]
    let literal: String
    let usageNote: String?
    let level: Int

    var id: String {
        key
    }

    var content: PhraseContent {
        PhraseContent(english: english, native: targetText, reading: reading, romanization: romanization)
    }
}
