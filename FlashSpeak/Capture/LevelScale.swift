/// Shows the internal 1–6 level on the scale learners know for each
/// language (PRD, Levels): HSK, JLPT, TOPIK or CEFR.
enum LevelScale {
    static func label(for level: Int, languageCode: String) -> String {
        let level = min(max(level, 1), 6)
        switch languageCode {
        case "zh-CN":
            return "HSK \(level)"
        case "ja":
            return ["JLPT N5", "JLPT N4", "JLPT N3", "JLPT N2", "JLPT N1", "JLPT N1+"][level - 1]
        case "ko":
            return "TOPIK \(level)"
        default:
            return ["A1", "A2", "B1", "B2", "C1", "C2"][level - 1]
        }
    }

    /// The range shown for a set level, e.g. "TOPIK 1–2" (one below and one above).
    static func range(around level: Int, languageCode: String) -> String {
        let low = label(for: max(level - 1, 1), languageCode: languageCode)
        let high = label(for: min(level + 1, 6), languageCode: languageCode)
        return low == high ? low : "\(low)–\(high.split(separator: " ").last ?? "")"
    }
}
