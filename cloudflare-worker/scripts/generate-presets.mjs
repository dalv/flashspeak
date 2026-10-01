// Generates the preset category content shipped inside the app
// (PRD, Phrase library; decision 0018). Runs locally, never in the Worker.
//
//   node scripts/generate-presets.mjs [zh-CN id ko ja]
//
// Uses the Worker's own translation prompt and model, with a short note per
// item, and reads ANTHROPIC_API_KEY from .dev.vars. Writes
// FlashSpeak/Presets/Content/presets.<lang>.json with `reviewed: false`
// until a native reviewer has checked it. Bump CONTENT_VERSION whenever
// regenerated content ships, so the app updates existing cards.

import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { generateJSON, MODEL } from "../src/anthropic.js";
import { LANGUAGES } from "../src/languages.js";
import * as prompts from "../src/prompts/v1.js";

const CONTENT_VERSION = 1;
const CONCURRENCY = 6;
const here = dirname(fileURLToPath(import.meta.url));
const outDir = join(here, "../../FlashSpeak/Presets/Content");

function readKey() {
  const vars = readFileSync(join(here, "../.dev.vars"), "utf8");
  const line = vars.split("\n").find((l) => l.startsWith("ANTHROPIC_API_KEY="));
  if (!line) throw new Error("ANTHROPIC_API_KEY missing from .dev.vars");
  return line.slice("ANTHROPIC_API_KEY=".length).trim();
}

// MARK: Items

const numberWords = {
  1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight", 9: "nine", 10: "ten",
  11: "eleven", 12: "twelve", 13: "thirteen", 14: "fourteen", 15: "fifteen", 16: "sixteen", 17: "seventeen",
  18: "eighteen", 19: "nineteen", 20: "twenty", 21: "twenty-one", 22: "twenty-two", 23: "twenty-three",
  30: "thirty", 34: "thirty-four", 40: "forty", 45: "forty-five", 50: "fifty", 56: "fifty-six", 67: "sixty-seven",
  78: "seventy-eight", 89: "eighty-nine", 95: "ninety-five", 100: "one hundred", 115: "one hundred and fifteen",
  250: "two hundred and fifty", 275: "two hundred and seventy-five", 500: "five hundred", 750: "seven hundred and fifty",
  945: "nine hundred and forty-five", 1000: "one thousand", 2500: "two thousand five hundred", 5000: "five thousand",
};

const NUMBERS = [...Array.from({ length: 23 }, (_, i) => i + 1), 34, 45, 56, 67, 78, 89, 95, 100, 115, 250, 275, 500, 750, 945, 1000, 2500, 5000];
const KOREAN_NATIVE = [...Array.from({ length: 20 }, (_, i) => i + 1), 30, 40, 50];

const numberNotes = {
  "zh-CN": (n) =>
    `Preset card for the number ${n} (the app shows the digits on the front). targetText is the number written in Chinese characters, as said aloud in everyday speech.` +
    (n === 2 ? " Use the counting form 二 and say in usageNote that 两 is used before a measure word (两个)." : "") +
    (n >= 200 && String(n).startsWith("2") ? " Use 两 where everyday speech does (两百, 两千)." : "") +
    (n === 2500 ? " Use the everyday spoken form 两千五." : ""),
  ja: (n) =>
    `Preset card for the number ${n} (the app shows the digits on the front). targetText is the number in kanji numerals; reading in hiragana.` +
    ([4, 7, 9, 14, 17, 19].includes(n) ? " Use the common reading (yon, nana, kyū) and give the other reading in usageNote." : ""),
  ko: (n) =>
    `Preset card for the Sino-Korean number ${n} (일, 이, 삼 system; the app shows the digits on the front). targetText in hangul.` +
    (n === 1 ? " usageNote: Sino-Korean numbers are used for prices, phone numbers, dates and minutes." : ""),
  id: (n) => `Preset card for the number ${n} (the app shows the digits on the front). targetText is the number written out in words as said aloud.`,
};

const wordNote = (kind) =>
  `Preset vocabulary card for the single ${kind} below. targetText is just the word or short expression on its own, not a sentence.`;
const exampleNote = (kind) =>
  `${wordNote(kind)} usageNote must give one short everyday example phrase in the target language using it, followed by its English meaning in brackets, because a lone word is hard to recall.`;

function itemsFor(code) {
  const categories = [];

  const numbers = NUMBERS.map((n) => ({
    key: String(n),
    front: String(n),
    english: numberWords[n],
    note: numberNotes[code](n),
  }));
  if (code === "ko") {
    for (const n of KOREAN_NATIVE) {
      numbers.push({
        key: `native-${n}`,
        front: `${n} · counting things`,
        english: numberWords[n],
        note:
          `Preset card for the native Korean number ${n} (하나, 둘, 셋 system), used for counting things, people, age and the hour. ` +
          `targetText is the number on its own in hangul. usageNote gives one everyday example with a counter (e.g. 한 개 one item, 두 명 two people, 세 시 three o'clock, 스무 살 twenty years old), choosing a natural counter for this number.`,
      });
    }
  }
  categories.push({ id: "numbers", items: numbers });

  const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday", "weekend"];
  categories.push({
    id: "days",
    items: days.map((d) => ({ key: d.toLowerCase(), front: d, english: d, note: wordNote("day word") })),
  });

  const connectors = [
    ["and", "and"], ["or", "or"], ["but", "but"], ["if", "if"], ["because", "because"], ["so", "so (as in 'so we left')"],
    ["when", "when (as in 'when I get home')"], ["then", "then (as in 'and then')"], ["also", "also"], ["before", "before"], ["after", "after"],
  ];
  categories.push({
    id: "connectors",
    items: connectors.map(([key, english]) => ({ key, front: key, english, note: exampleNote("connector word") })),
  });

  const questions = [
    ["what", "what"], ["who", "who"], ["where", "where"], ["when", "when (question)"], ["why", "why"], ["how", "how"],
    ["which", "which"], ["how-much", "how much (asking a price)"], ["how-many", "how many"],
  ];
  categories.push({
    id: "questions",
    items: questions.map(([key, english]) => ({
      key,
      front: english.replace(/ \(.*\)$/, "").replace("how much", "how much (price)"),
      english,
      note: exampleNote("question word"),
    })),
  });

  const time = [
    "now", "today", "tomorrow", "yesterday", "later", "soon", "already", "not yet", "morning", "afternoon",
    "evening", "tonight", "this week", "next week", "last week", "every day",
  ];
  categories.push({
    id: "time",
    items: time.map((t) => ({ key: t.replaceAll(" ", "-"), front: t, english: t, note: wordNote("time word") })),
  });

  return categories;
}

// MARK: Generation

// Cards are single words, so romanization starts lowercase.
const lowerFirst = (text) => (text ? text[0].toLowerCase() + text.slice(1) : null);

async function pool(tasks, limit) {
  const results = new Array(tasks.length);
  let next = 0;
  async function worker() {
    while (next < tasks.length) {
      const index = next++;
      results[index] = await tasks[index]();
    }
  }
  await Promise.all(Array.from({ length: limit }, worker));
  return results;
}

// Applies to every preset card.
const COMMON_NOTE =
  "Write usageNote in English. Use lowercase for a lone word unless the language always capitalizes it (for example Indonesian day names). " +
  "Leave usageNote null unless it says something specific to this card; don't repeat a general rule that applies to every card in the category.";

async function translateItem(env, lang, item) {
  const system = prompts.translateSystem(lang, "neutral");
  const user = `${prompts.translateUser(item.english)}\n\nNote: ${item.note} ${COMMON_NOTE}`;
  for (let attempt = 1; ; attempt++) {
    try {
      const raw = await generateJSON(env, { system, user, schema: prompts.TRANSLATION_SCHEMA });
      return raw;
    } catch (error) {
      if (attempt >= 3) throw new Error(`${item.key}: ${error.message}`);
      await new Promise((r) => setTimeout(r, 2000 * attempt));
    }
  }
}

async function generate(code, env) {
  const lang = LANGUAGES[code];
  const categories = itemsFor(code);
  const tasks = categories.flatMap((category) =>
    category.items.map((item) => async () => {
      const raw = await translateItem(env, lang, item);
      process.stdout.write(".");
      return { category: category.id, item, raw };
    }),
  );
  const results = await pool(tasks, CONCURRENCY);
  process.stdout.write("\n");

  const output = {
    language: code,
    contentVersion: CONTENT_VERSION,
    reviewed: false,
    promptVersion: prompts.VERSION,
    model: MODEL,
    generatedAt: new Date().toISOString().slice(0, 10),
    categories: categories.map((category) => ({
      id: category.id,
      items: results
        .filter((r) => r.category === category.id)
        .map(({ item, raw }) => ({
          key: item.key,
          english: item.front,
          targetText: raw.targetText,
          romanization: lang.romanization ? lowerFirst(raw.romanization) : null,
          reading: lang.reading ? raw.reading ?? null : null,
          gloss: (raw.gloss ?? []).map((g) => ({
            target: g.target,
            romanization: lang.romanization ? lowerFirst(g.romanization) : null,
            english: g.english,
          })),
          literal: raw.literal ?? "",
          usageNote: raw.usageNote || null,
          level: Number.isInteger(raw.level) ? Math.min(Math.max(raw.level, 1), 6) : 1,
        })),
    })),
  };
  const file = join(outDir, `presets.${code}.json`);
  writeFileSync(file, JSON.stringify(output, null, 2) + "\n");
  const count = output.categories.reduce((n, c) => n + c.items.length, 0);
  console.log(`${code}: ${count} items -> ${file}`);
}

const codes = process.argv.slice(2).length ? process.argv.slice(2) : Object.keys(LANGUAGES);
const env = { ANTHROPIC_API_KEY: readKey() };
for (const code of codes) {
  if (!LANGUAGES[code]) throw new Error(`Unknown language ${code}`);
  await generate(code, env);
}
