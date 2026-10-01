@testable import FlashSpeak
import Testing

struct LevelScaleTests {
    @Test(arguments: [
        (1, "zh-CN", "HSK 1"), (6, "zh-CN", "HSK 6"),
        (1, "ja", "JLPT N5"), (2, "ja", "JLPT N4"), (5, "ja", "JLPT N1"), (6, "ja", "JLPT N1+"),
        (1, "ko", "TOPIK 1"), (4, "ko", "TOPIK 4"),
        (1, "id", "A1"), (3, "id", "B1"), (6, "id", "C2"),
    ])
    func labels(level: Int, language: String, expected: String) {
        #expect(LevelScale.label(for: level, languageCode: language) == expected)
    }

    @Test func outOfRangeLevelsAreClamped() {
        #expect(LevelScale.label(for: 0, languageCode: "zh-CN") == "HSK 1")
        #expect(LevelScale.label(for: 9, languageCode: "id") == "C2")
    }

    @Test func rangeAroundALevel() {
        #expect(LevelScale.range(around: 1, languageCode: "ko") == "TOPIK 1–2")
        #expect(LevelScale.range(around: 3, languageCode: "zh-CN") == "HSK 2–4")
        #expect(LevelScale.range(around: 2, languageCode: "id") == "A1–B1")
    }
}
