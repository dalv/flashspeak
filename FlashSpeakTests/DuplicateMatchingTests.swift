@testable import FlashSpeak
import Testing

struct DuplicateMatchingTests {
    @Test(arguments: [
        ("Where's the bathroom?", "where's the bathroom"),
        ("  Where’s   the bathroom  ", "where's the bathroom"),
        ("HOW MUCH is this!!", "how much is this"),
    ])
    func englishVariantsNormalizeAlike(a: String, b: String) {
        #expect(PhraseNormalizer.normalize(a) == PhraseNormalizer.normalize(b))
    }

    @Test func fullWidthAndHalfWidthCJKPunctuationMatch() {
        #expect(PhraseNormalizer.normalize("你能再说一遍吗？慢一点。") == PhraseNormalizer.normalize("你能再说一遍吗?慢一点"))
        #expect(PhraseNormalizer.normalize("駅はどこですか？") == PhraseNormalizer.normalize("駅はどこですか"))
    }

    @Test func differentPhrasesStayDifferent() {
        #expect(PhraseNormalizer.normalize("Turn left") != PhraseNormalizer.normalize("Turn right"))
    }

    private let existing: [ExactDuplicateMatcher.Candidate] = [
        .init(english: "Thank you", target: "谢谢"),
        .init(english: "Where's the bathroom?", target: "洗手间在哪儿？"),
    ]

    @Test func matchesOnEnglish() {
        #expect(ExactDuplicateMatcher.firstMatch(english: "where's the BATHROOM", target: nil, in: existing) == 1)
    }

    @Test func matchesOnTranslationWhenEnglishDiffers() {
        #expect(ExactDuplicateMatcher.firstMatch(english: "Thanks", target: "谢谢！", in: existing) == 0)
    }

    @Test func noMatchForNewPhrase() {
        #expect(ExactDuplicateMatcher.firstMatch(english: "No spicy, please", target: "不要辣", in: existing) == nil)
    }

    @Test func emptyTranslationNeverMatches() {
        let withEmpty = [ExactDuplicateMatcher.Candidate(english: "Hello", target: "")]
        #expect(ExactDuplicateMatcher.firstMatch(english: "Goodbye", target: "", in: withEmpty) == nil)
    }
}
