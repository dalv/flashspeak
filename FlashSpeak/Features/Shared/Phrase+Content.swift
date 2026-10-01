import Foundation

extension Phrase {
    /// The phrase as design-system components show it.
    var content: PhraseContent {
        PhraseContent(
            english: englishText,
            native: targetText,
            reading: reading,
            romanization: pronunciation.isEmpty ? nil : pronunciation,
            level: level.map { LevelScale.label(for: $0, languageCode: languageCode) }
        )
    }
}
