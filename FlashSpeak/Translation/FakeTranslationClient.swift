import Foundation

/// A `TranslationClient` for Previews and tests: answers from fixed sample
/// data in all four languages, after an optional delay.
struct FakeTranslationClient: TranslationClient {
    var delay: Duration = .zero
    var failure: TranslationError?

    func translate(_ request: TranslationRequest) async throws(TranslationError) -> TranslationResult {
        try await wait()
        let list = Self.samples[request.language] ?? Self.samples["zh-CN"]!
        if let match = list.first(where: { $0.english.lowercased() == request.english.lowercased() }) {
            return match.result
        }
        return Self.sample(for: request.language, index: request.english.count % 4)
    }

    func clarify(_ request: ClarificationRequest) async throws(TranslationError) -> ClarificationResult {
        try await wait()
        let first = Self.sample(for: request.language, index: 2)
        let second = Self.sample(for: request.language, index: 3)
        return ClarificationResult(
            explanation: "You may be thinking of a shorter, more casual way to say it.",
            keepsCurrent: false,
            candidates: [first, second]
        )
    }

    func suggest(_ request: SuggestionRequest) async throws(TranslationError) -> [SuggestedPhrase] {
        try await wait()
        let samples = Self.samples[request.language] ?? Self.samples["zh-CN"]!
        return samples.prefix(request.count).map { SuggestedPhrase(english: $0.english, translation: $0.result) }
    }

    func flag(_: TranslationFlag) async throws(TranslationError) {
        try await wait()
    }

    private func wait() async throws(TranslationError) {
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        if let failure {
            throw failure
        }
    }

    // MARK: - Sample data

    private struct Sample {
        let english: String
        let result: TranslationResult
    }

    private static func sample(for language: String, index: Int) -> TranslationResult {
        let list = samples[language] ?? samples["zh-CN"]!
        return list[index % list.count].result
    }

    private static func result(
        _ target: String, _ romanization: String?, reading: String? = nil,
        gloss: [GlossPair], literal: String, level: Int, note: String? = nil
    ) -> TranslationResult {
        TranslationResult(
            targetText: target, romanization: romanization, reading: reading, gloss: gloss,
            literal: literal, alternative: nil, usageNote: note, level: level, promptVersion: "fake"
        )
    }

    private static let samples: [String: [Sample]] = [
        "zh-CN": [
            Sample(english: "Can you say that one more time, slowly?", result: result(
                "你能再说一遍吗？慢一点。", "Nǐ néng zài shuō yí biàn ma? Màn yìdiǎn.",
                gloss: [
                    GlossPair(target: "你", romanization: "nǐ", english: "you"),
                    GlossPair(target: "能", romanization: "néng", english: "can"),
                    GlossPair(target: "再", romanization: "zài", english: "again"),
                    GlossPair(target: "说", romanization: "shuō", english: "say"),
                    GlossPair(target: "一遍", romanization: "yí biàn", english: "one time"),
                    GlossPair(target: "吗", romanization: "ma", english: "(question)"),
                    GlossPair(target: "慢", romanization: "màn", english: "slow"),
                    GlossPair(target: "一点", romanization: "yìdiǎn", english: "a bit"),
                ],
                literal: "you can again say one time? slow a bit.", level: 2
            )),
            Sample(english: "Where's the bathroom?", result: result(
                "洗手间在哪儿？", "Xǐshǒujiān zài nǎr?",
                gloss: [
                    GlossPair(target: "洗手间", romanization: "xǐshǒujiān", english: "bathroom"),
                    GlossPair(target: "在", romanization: "zài", english: "is at"),
                    GlossPair(target: "哪儿", romanization: "nǎr", english: "where"),
                ],
                literal: "bathroom at where?", level: 2
            )),
            Sample(english: "Let's take a taxi", result: result(
                "我们打车吧", "Wǒmen dǎchē ba",
                gloss: [
                    GlossPair(target: "我们", romanization: "wǒmen", english: "we"),
                    GlossPair(target: "打车", romanization: "dǎchē", english: "take a taxi"),
                    GlossPair(target: "吧", romanization: "ba", english: "(suggestion)"),
                ],
                literal: "we hail-car (let's)", level: 2, note: "打车 is the everyday word for getting a taxi or ride-hail."
            )),
            Sample(english: "How much?", result: result(
                "多少钱？", "Duōshao qián?",
                gloss: [
                    GlossPair(target: "多少", romanization: "duōshao", english: "how much"),
                    GlossPair(target: "钱", romanization: "qián", english: "money"),
                ],
                literal: "how much money?", level: 1
            )),
        ],
        "id": [
            Sample(english: "I'm already on my way.", result: result(
                "Aku udah di jalan.", nil,
                gloss: [
                    GlossPair(target: "Aku", english: "I"), GlossPair(target: "udah", english: "already"),
                    GlossPair(target: "di", english: "on/at"), GlossPair(target: "jalan", english: "road"),
                ],
                literal: "I already at road.", level: 2, note: "udah is the spoken form of sudah."
            )),
            Sample(english: "How much is this?", result: result(
                "Ini berapa?", nil,
                gloss: [GlossPair(target: "Ini", english: "this"), GlossPair(target: "berapa", english: "how much")],
                literal: "this how much?", level: 1
            )),
            Sample(english: "Not spicy, please", result: result(
                "Jangan pedas, ya", nil,
                gloss: [GlossPair(target: "Jangan", english: "don't"), GlossPair(target: "pedas", english: "spicy"), GlossPair(target: "ya", english: "(softener)")],
                literal: "don't spicy, yeah", level: 2
            )),
            Sample(english: "Can you say it again, slowly?", result: result(
                "Bisa diulang lagi, pelan-pelan?", nil,
                gloss: [GlossPair(target: "Bisa", english: "can"), GlossPair(target: "diulang", english: "be repeated"), GlossPair(target: "lagi", english: "again"), GlossPair(target: "pelan-pelan", english: "slowly")],
                literal: "can be-repeated again, slowly?", level: 2
            )),
        ],
        "ko": [
            Sample(english: "An iced Americano, please", result: result(
                "아이스 아메리카노 한 잔 주세요", "aiseu amerikano han jan juseyo",
                gloss: [
                    GlossPair(target: "아이스 아메리카노", romanization: "aiseu amerikano", english: "iced Americano"),
                    GlossPair(target: "한 잔", romanization: "han jan", english: "one cup"),
                    GlossPair(target: "주세요", romanization: "juseyo", english: "please give"),
                ],
                literal: "iced americano one cup please-give", level: 1
            )),
            Sample(english: "For here, please", result: result(
                "여기서 마시고 갈게요", "yeogiseo masigo galgeyo",
                gloss: [
                    GlossPair(target: "여기서", romanization: "yeogiseo", english: "here"),
                    GlossPair(target: "마시고", romanization: "masigo", english: "drink and"),
                    GlossPair(target: "갈게요", romanization: "galgeyo", english: "will go"),
                ],
                literal: "here drink-and will-go", level: 2
            )),
            Sample(english: "To go, please", result: result(
                "테이크아웃이요", "teikeuausiyo",
                gloss: [GlossPair(target: "테이크아웃이요", romanization: "teikeuausiyo", english: "takeout, please")],
                literal: "takeout (polite)", level: 1
            )),
            Sample(english: "Where's the restroom?", result: result(
                "화장실이 어디예요?", "hwajangsiri eodiyeyo?",
                gloss: [GlossPair(target: "화장실이", romanization: "hwajangsiri", english: "restroom"), GlossPair(target: "어디예요", romanization: "eodiyeyo", english: "where is")],
                literal: "restroom where-is?", level: 1
            )),
        ],
        "ja": [
            Sample(english: "Could I get the check, please?", result: result(
                "お会計お願いします", "okaikei onegaishimasu", reading: "おかいけい おねがいします",
                gloss: [
                    GlossPair(target: "お会計", romanization: "okaikei", english: "the bill"),
                    GlossPair(target: "お願いします", romanization: "onegaishimasu", english: "please"),
                ],
                literal: "bill please", level: 2
            )),
            Sample(english: "I'm already on my way.", result: result(
                "もう向かってるよ", "mō mukatteru yo", reading: "もう むかってるよ",
                gloss: [
                    GlossPair(target: "もう", romanization: "mō", english: "already"),
                    GlossPair(target: "向かってる", romanization: "mukatteru", english: "heading there"),
                    GlossPair(target: "よ", romanization: "yo", english: "(emphasis)"),
                ],
                literal: "already heading-there!", level: 2, note: "Plain form: for friends."
            )),
            Sample(english: "Where is the station?", result: result(
                "駅はどこですか？", "eki wa doko desu ka?", reading: "えきは どこですか？",
                gloss: [
                    GlossPair(target: "駅", romanization: "eki", english: "station"),
                    GlossPair(target: "は", romanization: "wa", english: "(topic)"),
                    GlossPair(target: "どこですか", romanization: "doko desu ka", english: "where is it"),
                ],
                literal: "station (topic) where is?", level: 1
            )),
            Sample(english: "Just a little, please", result: result(
                "少しだけお願いします", "sukoshi dake onegaishimasu", reading: "すこしだけ おねがいします",
                gloss: [
                    GlossPair(target: "少し", romanization: "sukoshi", english: "a little"),
                    GlossPair(target: "だけ", romanization: "dake", english: "only"),
                    GlossPair(target: "お願いします", romanization: "onegaishimasu", english: "please"),
                ],
                literal: "a little only please", level: 2
            )),
        ],
    ]
}
