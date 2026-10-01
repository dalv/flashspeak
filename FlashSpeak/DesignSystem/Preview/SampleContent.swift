/// Realistic sample phrases in the four supported languages, for Previews.
/// The first phrases match the mockups.
enum SampleContent {
    static let mandarin = SampleLanguage(theme: .mandarin, phrases: [
        PhraseContent(
            english: "Can you say that one more time, slowly?",
            native: "你能再说一遍吗？慢一点。",
            romanization: "Nǐ néng zài shuō yí biàn ma? Màn yìdiǎn.",
            level: "HSK 2"
        ),
        PhraseContent(english: "Where’s the bathroom?", native: "洗手间在哪儿？", romanization: "Xǐshǒujiān zài nǎr?", level: "HSK 2"),
        PhraseContent(english: "How much is this?", native: "这个多少钱？", romanization: "Zhège duōshao qián?", level: "HSK 1"),
        PhraseContent(english: "No spicy, please", native: "不要辣", romanization: "Bú yào là", level: "HSK 2"),
    ])

    static let indonesian = SampleLanguage(theme: .indonesian, phrases: [
        PhraseContent(english: "I’m already on my way.", native: "Aku udah di jalan.", level: "A2"),
        PhraseContent(english: "Can you say that again, slowly?", native: "Bisa diulang lagi, pelan-pelan?", level: "A2"),
        PhraseContent(english: "How much is this?", native: "Ini berapa?", level: "A1"),
        PhraseContent(english: "Not spicy, please", native: "Jangan pedas, ya", level: "A2"),
    ])

    static let korean = SampleLanguage(theme: .korean, phrases: [
        PhraseContent(
            english: "An iced Americano, please",
            native: "아이스 아메리카노 한 잔 주세요",
            romanization: "aiseu amerikano han jan juseyo",
            level: "TOPIK 1"
        ),
        PhraseContent(english: "For here, please", native: "여기서 마시고 갈게요", romanization: "yeogiseo masigo galgeyo", level: "TOPIK 2"),
        PhraseContent(english: "To go, please", native: "테이크아웃이요", romanization: "teikeuausiyo", level: "TOPIK 1"),
        PhraseContent(english: "Where’s the restroom?", native: "화장실이 어디예요?", romanization: "hwajangsiri eodiyeyo?", level: "TOPIK 1"),
    ])

    static let japanese = SampleLanguage(theme: .japanese, phrases: [
        PhraseContent(
            english: "Could I get the check, please?",
            native: "お会計お願いします",
            reading: "おかいけい おねがいします",
            romanization: "okaikei onegaishimasu",
            level: "JLPT N4"
        ),
        PhraseContent(
            english: "I’m already on my way.",
            native: "もう向かってるよ",
            reading: "もう むかってるよ",
            romanization: "mō mukatteru yo",
            level: "JLPT N4"
        ),
        PhraseContent(
            english: "Where is the station?",
            native: "駅はどこですか？",
            reading: "えきは どこですか？",
            romanization: "eki wa doko desu ka?",
            level: "JLPT N5"
        ),
        PhraseContent(
            english: "Just a little, please",
            native: "少しだけお願いします",
            reading: "すこしだけ おねがいします",
            romanization: "sukoshi dake onegaishimasu",
            level: "JLPT N4"
        ),
    ])

    static let languages: [SampleLanguage] = [mandarin, indonesian, korean, japanese]

    static func language(for theme: LanguageTheme) -> SampleLanguage {
        languages.first { $0.theme == theme } ?? mandarin
    }
}
