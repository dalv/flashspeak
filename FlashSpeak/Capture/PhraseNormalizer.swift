import Foundation

/// Normalizes text for exact-duplicate matching: ignores case, punctuation,
/// full-width vs half-width forms and extra spaces. Shared by duplicate
/// detection and suggestion filtering.
enum PhraseNormalizer {
    static func normalize(_ text: String) -> String {
        // NFKC folds full-width forms (？, ！, Ａ) into their ASCII equivalents.
        let folded = text.precomposedStringWithCompatibilityMapping
            .lowercased(with: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "’", with: "'")

        var result = ""
        var pendingSpace = false
        for character in folded {
            if character.isPunctuation || character.isSymbol {
                continue
            }
            if character.isWhitespace {
                pendingSpace = !result.isEmpty
                continue
            }
            if pendingSpace {
                result.append(" ")
                pendingSpace = false
            }
            result.append(character)
        }
        return result
    }
}
