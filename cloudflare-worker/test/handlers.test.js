import assert from "node:assert/strict";
import { test } from "node:test";
import { BadRequest, clarify, suggest, translate } from "../src/v2/handlers.js";
import { LANGUAGES } from "../src/languages.js";

const zhResult = {
  targetText: " 多少钱？ ",
  romanization: "Duōshao qián?",
  reading: "ignored",
  gloss: [{ target: "多少", romanization: "duōshao", english: "how much" }],
  literal: "how much money?",
  alternative: "",
  usageNote: null,
  level: 9,
};

test("translate rejects unsupported languages and empty text", async () => {
  await assert.rejects(translate({ english: "hi", language: "es" }, async () => ({})), BadRequest);
  await assert.rejects(translate({ english: "  ", language: "ja" }, async () => ({})), BadRequest);
});

test("translate normalizes the model result", async () => {
  let seen;
  const result = await translate({ english: "How much?", language: "zh-CN", register: "bogus" }, async (o) => {
    seen = o;
    return zhResult;
  });
  assert.equal(result.targetText, "多少钱？");
  assert.equal(result.reading, null, "Mandarin has no kana reading");
  assert.equal(result.alternative, null, "empty strings become null");
  assert.equal(result.level, 6, "level is clamped to 1–6");
  assert.equal(result.promptVersion, "2026-10.1");
  assert.match(seen.system, /Everyday spoken Mainland Mandarin/, "unknown register falls back to casual");
  assert.equal(seen.user, "English: How much?");
});

test("Indonesian never gets romanization", async () => {
  const result = await translate({ english: "How much?", language: "id" }, async () => ({ ...zhResult, targetText: "Berapa?" }));
  assert.equal(result.romanization, null);
  assert.equal(result.gloss[0].romanization, null);
});

test("clarify sends history and keeps at most three candidates", async () => {
  let seen;
  const result = await clarify(
    {
      english: "Let's take a taxi",
      language: "zh-CN",
      currentTargetText: "我们坐出租车吧",
      history: [{ clarification: "shorter", targetText: "坐车吧" }],
      clarification: "it was something like dai cha",
    },
    async (o) => {
      seen = o;
      return { explanation: "You may mean 打车.", keepsCurrent: false, candidates: [zhResult, zhResult, zhResult, zhResult] };
    },
  );
  assert.equal(result.candidates.length, 3);
  assert.equal(result.keepsCurrent, false);
  assert.match(seen.user, /Earlier clarification: shorter/);
  assert.match(seen.user, /Clarification: it was something like dai cha/);
  assert.match(seen.system, /rough phonetic spelling/);
});

test("clarify with no usable candidates keeps the current translation", async () => {
  const result = await clarify(
    { english: "Hi", language: "ko", currentTargetText: "안녕하세요", clarification: "is this right?" },
    async () => ({ explanation: "That's already right.", keepsCurrent: false, candidates: [] }),
  );
  assert.equal(result.keepsCurrent, true);
});

test("suggest clamps count and passes existing phrases", async () => {
  let seen;
  const result = await suggest(
    { language: "ja", category: "At a café", level: 2, existing: ["Coffee, please"], count: 2 },
    async (o) => {
      seen = o;
      return { phrases: [1, 2, 3].map((i) => ({ english: `Phrase ${i}`, ...zhResult })) };
    },
  );
  assert.equal(result.phrases.length, 2);
  assert.equal(result.phrases[0].translation.reading, "ignored", "Japanese keeps its reading");
  assert.match(seen.user, /- Coffee, please/);
});

test("the Worker's languages match the app's supported codes", () => {
  assert.deepEqual(Object.keys(LANGUAGES).sort(), ["id", "ja", "ko", "zh-CN"]);
});
