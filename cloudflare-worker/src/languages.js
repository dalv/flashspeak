// The four supported languages. Must stay in sync with
// `Language.supportedCodes` in FlashSpeak/Models/Language.swift.
// A code not listed here returns a 400.

export const LANGUAGES = {
  "zh-CN": {
    name: "Mandarin Chinese",
    script: "simplified Chinese characters",
    romanization: "Hanyu Pinyin with tone marks (e.g. nǐ hǎo), words separated by spaces, sentence-initial capital",
    reading: null,
    levelScale: "HSK 1–6",
    registers: {
      casual:
        "Everyday spoken Mainland Mandarin, the way a friendly local talks: natural particles (吧, 呢, 啊) where they fit. Avoid written-style or literary phrasing.",
      neutral: "Standard, neutral spoken Mandarin suitable for strangers and service situations.",
      polite: "Polite Mandarin (您, 请, 麻烦你) suitable for elders or formal situations, still spoken rather than written style.",
    },
  },
  id: {
    name: "Indonesian",
    script: "Latin script",
    romanization: null,
    reading: null,
    levelScale: "CEFR A1–C2",
    registers: {
      casual:
        "Everyday spoken Indonesian (bahasa sehari-hari): aku/kamu, natural particles like sih, dong, kok, ya where they fit, colloquial forms like udah, nggak. Avoid formal written Indonesian (saya/Anda everywhere) and heavy Jakarta slang (gue/lo).",
      neutral: "Neutral spoken Indonesian: saya/kamu, standard forms, no slang.",
      polite: "Polite Indonesian: saya/Anda or Bapak/Ibu, standard forms, as with elders or in professional settings.",
    },
  },
  ko: {
    name: "Korean",
    script: "Hangul",
    romanization: "Revised Romanization of Korean, lowercase, words separated as in the Hangul",
    reading: null,
    levelScale: "TOPIK 1–6",
    registers: {
      casual: "Polite informal Korean (-요 endings), natural and conversational. Avoid formal -습니다 endings and banmal.",
      neutral: "Polite informal Korean (-요 endings) in a neutral, standard style.",
      polite: "Formal polite Korean (-습니다 / -십시오 endings and honorifics where natural).",
    },
  },
  ja: {
    name: "Japanese",
    script: "Japanese (kanji and kana as a native speaker would write it)",
    romanization: "modified Hepburn romaji with macrons for long vowels (ō, ū), words separated by spaces, lowercase",
    reading: "the whole phrase in hiragana (katakana loanwords may stay in katakana), with spaces between words",
    levelScale: "JLPT N5–N1",
    registers: {
      casual:
        "Casual polite Japanese (desu/masu) as you would use with friendly strangers. Avoid keigo and textbook stiffness.",
      neutral: "Standard desu/masu Japanese.",
      polite: "Polite Japanese with appropriate keigo (お願いいたします, いらっしゃいます) for formal situations.",
    },
  },
};

export const REGISTERS = ["casual", "neutral", "polite"];

/** The language config, or null if unsupported. */
export function languageFor(code) {
  return Object.hasOwn(LANGUAGES, code) ? LANGUAGES[code] : null;
}
