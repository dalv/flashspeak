/// The current level of a language set, on the internal 1–6 scale.
enum SetLevel {
    static let sampleSize = 50
    static let range = 1 ... 6

    /// - Parameters:
    ///   - levels: levels of the set's phrases, newest first; nil for unknown.
    ///   - override: the user's override from Settings, if any.
    /// - Returns: the override, else the median of the most recent 50 known
    ///   levels (the lower middle for an even count), else 1 for a new set.
    static func current(levels: [Int?], override: Int?) -> Int {
        if let override {
            return clamp(override)
        }
        let recent = levels.compactMap { $0 }.prefix(sampleSize).sorted()
        guard !recent.isEmpty else { return range.lowerBound }
        return clamp(recent[(recent.count - 1) / 2])
    }

    private static func clamp(_ level: Int) -> Int {
        min(max(level, range.lowerBound), range.upperBound)
    }
}
