import { languageFor, REGISTERS } from "../languages.js";
import * as prompts from "../prompts/v1.js";

// v2 endpoint logic. `generate(options)` performs the model call; it is
// injected so the handlers can be tested without the API.

export class BadRequest extends Error {}

const MAX_TEXT = 500;
const MAX_HISTORY = 10;
const MAX_EXISTING = 300;

function requireText(value, field, max = MAX_TEXT) {
  if (typeof value !== "string" || !value.trim()) throw new BadRequest(`Missing '${field}'`);
  if (value.length > max) throw new BadRequest(`'${field}' is too long`);
  return value.trim();
}

function requireLanguage(code) {
  const lang = languageFor(code);
  if (!lang) throw new BadRequest(`Unsupported language: ${code}`);
  return lang;
}

function registerOf(value) {
  return REGISTERS.includes(value) ? value : "casual";
}

/** Normalizes a model result to the app's TranslationResult shape. */
export function toTranslation(raw, lang) {
  const nullIfEmpty = (v) => (typeof v === "string" && v.trim() ? v.trim() : null);
  return {
    targetText: String(raw.targetText ?? "").trim(),
    romanization: lang.romanization ? nullIfEmpty(raw.romanization) : null,
    reading: lang.reading ? nullIfEmpty(raw.reading) : null,
    gloss: (Array.isArray(raw.gloss) ? raw.gloss : []).map((g) => ({
      target: String(g.target ?? ""),
      romanization: lang.romanization ? nullIfEmpty(g.romanization) : null,
      english: String(g.english ?? ""),
    })),
    literal: String(raw.literal ?? ""),
    alternative: nullIfEmpty(raw.alternative),
    usageNote: nullIfEmpty(raw.usageNote),
    level: Number.isInteger(raw.level) ? Math.min(Math.max(raw.level, 1), 6) : null,
    promptVersion: prompts.VERSION,
  };
}

export async function translate(body, generate) {
  const english = requireText(body.english, "english");
  const lang = requireLanguage(body.language);
  const register = registerOf(body.register);
  const raw = await generate({
    system: prompts.translateSystem(lang, register),
    user: prompts.translateUser(english),
    schema: prompts.TRANSLATION_SCHEMA,
  });
  return toTranslation(raw, lang);
}

export async function clarify(body, generate) {
  const english = requireText(body.english, "english");
  const lang = requireLanguage(body.language);
  const register = registerOf(body.register);
  const request = {
    english,
    currentTargetText: requireText(body.currentTargetText, "currentTargetText"),
    currentRomanization: typeof body.currentRomanization === "string" ? body.currentRomanization : null,
    history: (Array.isArray(body.history) ? body.history : []).slice(-MAX_HISTORY).map((turn) => ({
      clarification: requireText(turn?.clarification, "history.clarification"),
      targetText: requireText(turn?.targetText, "history.targetText"),
    })),
    clarification: requireText(body.clarification, "clarification"),
  };
  const raw = await generate({
    system: prompts.clarifySystem(lang, register),
    user: prompts.clarifyUser(request),
    schema: prompts.CLARIFY_SCHEMA,
  });
  const keepsCurrent = raw.keepsCurrent === true;
  const candidates = keepsCurrent
    ? []
    : (Array.isArray(raw.candidates) ? raw.candidates : [])
        .map((c) => toTranslation(c, lang))
        .filter((c) => c.targetText)
        .slice(0, 3);
  return {
    explanation: String(raw.explanation ?? "").trim(),
    keepsCurrent: keepsCurrent || candidates.length === 0,
    candidates,
  };
}

export async function suggest(body, generate) {
  const lang = requireLanguage(body.language);
  const register = registerOf(body.register);
  const category = requireText(body.category, "category", 120);
  const level = Number.isInteger(body.level) ? Math.min(Math.max(body.level, 1), 6) : 1;
  const count = Number.isInteger(body.count) ? Math.min(Math.max(body.count, 1), 10) : 5;
  const existing = (Array.isArray(body.existing) ? body.existing : [])
    .filter((e) => typeof e === "string")
    .slice(0, MAX_EXISTING);

  const raw = await generate({
    system: prompts.suggestSystem(lang, register),
    user: prompts.suggestUser({ category, level, existing, count }),
    schema: prompts.SUGGEST_SCHEMA,
  });
  const phrases = (Array.isArray(raw.phrases) ? raw.phrases : [])
    .map((p) => ({ english: String(p.english ?? "").trim(), translation: toTranslation(p, lang) }))
    .filter((p) => p.english && p.translation.targetText)
    .slice(0, count);
  return { phrases, promptVersion: prompts.VERSION };
}

/** Logs a bad-translation report. Stored in D1 later (decision 0007). */
export function flag(body) {
  requireText(body.english, "english");
  requireLanguage(body.language);
  console.log("Translation flagged", JSON.stringify({
    english: body.english,
    language: body.language,
    targetText: body.targetText,
    promptVersion: body.promptVersion,
    clarifications: body.clarifications,
    note: body.note,
  }));
  return { ok: true };
}

export function config() {
  return {
    languages: ["zh-CN", "id", "ko", "ja"],
    promptVersion: prompts.VERSION,
    freeTranslationsPerDay: 3,
    freeClarificationsPerPhrase: 3,
  };
}
