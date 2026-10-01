import Foundation

/// Exports phrases as CSV (decision 0020): one row per phrase, RFC 4180
/// quoting, UTF-8 with a byte order mark so spreadsheet apps read hanzi,
/// kana and hangul correctly.
enum CSVExporter {
    static let header = ["Language", "English", "Translation", "Romanization", "Reading", "Level", "Section", "Created"]

    static func csv(for phrases: [Phrase]) -> String {
        let dateFormat = Date.ISO8601FormatStyle().year().month().day()
        let rows = phrases.map { phrase in
            [
                LanguageTheme.forCode(phrase.languageCode)?.displayName ?? phrase.languageCode,
                phrase.englishText,
                phrase.targetText,
                phrase.pronunciation,
                phrase.reading ?? "",
                phrase.level.map { LevelScale.label(for: $0, languageCode: phrase.languageCode) } ?? "",
                phrase.presetCategory.map { PresetCategoryKind(rawValue: $0)?.title ?? $0 } ?? "User phrases",
                phrase.createdAt.formatted(dateFormat),
            ]
        }
        return ([header] + rows).map { $0.map(escape).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
    }

    static func data(for phrases: [Phrase]) -> Data {
        Data("\u{FEFF}".utf8) + Data(csv(for: phrases).utf8)
    }

    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
