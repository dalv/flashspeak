/// Maps a range the speech engine reports to the gloss word that contains
/// it, so the word tile can highlight while it is spoken.
enum GlossHighlighter {
    static func index(of range: Range<String.Index>, in text: String, gloss: [GlossPair]) -> Int? {
        let offset = text.distance(from: text.startIndex, to: range.lowerBound)
        var position = 0
        for (index, pair) in gloss.enumerated() {
            let searchStart = text.index(text.startIndex, offsetBy: position)
            guard let found = text.range(of: pair.target, range: searchStart ..< text.endIndex) else {
                continue
            }
            let start = text.distance(from: text.startIndex, to: found.lowerBound)
            let end = text.distance(from: text.startIndex, to: found.upperBound)
            if offset >= start, offset < end {
                return index
            }
            position = end
        }
        return nil
    }
}
