// Prompt version 1. Prompts are versioned data: a change ships as a new
// file and a new VERSION, and only if it does at least as well on the
// evaluation set (PRD, Translation quality spec).

export const VERSION = "2026-10.1";

const nullableString = { anyOf: [{ type: "string" }, { type: "null" }] };

const translationProperties = {
  targetText: { type: "string", description: "The translation in native script." },
  romanization: nullableString,
  reading: nullableString,
  gloss: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: ["target", "romanization", "english"],
      properties: {
        target: { type: "string" },
        romanization: nullableString,
        english: { type: "string" },
      },
    },
  },
  literal: { type: "string" },
  alternative: nullableString,
  usageNote: nullableString,
  level: { type: "integer", enum: [1, 2, 3, 4, 5, 6] },
};

const translationRequired = Object.keys(translationProperties);

export const TRANSLATION_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: translationRequired,
  properties: translationProperties,
};

export const CLARIFY_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["explanation", "keepsCurrent", "candidates"],
  properties: {
    explanation: { type: "string" },
    keepsCurrent: { type: "boolean" },
    candidates: { type: "array", items: TRANSLATION_SCHEMA },
  },
};

export const SUGGEST_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["phrases"],
  properties: {
    phrases: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["english", ...translationRequired],
        properties: { english: { type: "string" }, ...translationProperties },
      },
    },
  },
};

function fieldRules(lang) {
  return `Fill every field:
- targetText: the phrase in ${lang.script}, with natural punctuation.
- romanization: ${lang.romanization ? lang.romanization : "null (this language uses Latin script)"}.
- reading: ${lang.reading ? lang.reading : "null"}.
- gloss: the targetText split into words or short chunks, in order, each with its ${lang.romanization ? "romanization" : "romanization set to null"} and a short English meaning. Particles get a bracketed role, e.g. "(question)". Joining all "target" values must reproduce targetText without punctuation.
- literal: a word-for-word English rendering that shows the structure.
- alternative: one other common way to say it (for example more casual or shorter) only if a natural one exists, else null.
- usageNote: one short sentence only when it matters (who you'd say it to, a nuance, a common pitfall), else null.
- level: the phrase's difficulty on the internal 1–6 scale, mapped from ${lang.levelScale} (1 is the easiest level of that scale).`;
}

function registerRule(lang, register) {
  return lang.registers[register] ?? lang.registers.casual;
}

export function translateSystem(lang, register) {
  return `You translate English phrases into ${lang.name} for an English-speaking adult who wants to talk with locals.

Translate the way a friendly native speaker would actually say it out loud in that situation, not a textbook or a literal rendering. Keep the meaning and intent; adapt idioms to what a native would naturally say.

Register: ${registerRule(lang, register)}

If the English is a fragment ("one more time", "turn left"), translate it as the natural fragment. If it is ambiguous, pick the most likely everyday meaning.

${fieldRules(lang)}`;
}

export function clarifySystem(lang, register) {
  return `You help an English-speaking learner of ${lang.name} get the translation they actually wanted.

They said a phrase in English and got a translation. Now they add a clarification in their own words. It may:
- describe what they heard or half-remember, as a rough phonetic spelling, e.g. "it was something like dai cha" or "like duo shao something". These hints come from English speech recognition, so they may be garbled ("dye char" for "dai cha"); match them by sound against plausible ${lang.name} words, not by English meaning.
- ask for a different register or nuance, e.g. "a more informal version", "to a friend, not a waiter".
- correct the meaning, e.g. "I meant the bill, not the check-in".

Return 1 to 3 candidate translations of the original English that fit the clarification, best first. Each candidate is a complete result. Prefer one candidate when the intent is clear; offer up to three only when the hint is genuinely ambiguous.

explanation: one short, friendly sentence in English saying what changed or what they were probably thinking of, including the native word and its romanization when a sounded-out hint matched one (e.g. "You may mean 打车 dǎchē, 'take a taxi'.").

If the clarification shows the current translation is already what they wanted, set keepsCurrent to true, return no candidates, and say so in the explanation.

Default register unless the clarification asks otherwise: ${registerRule(lang, register)}

For each candidate:
${fieldRules(lang)}`;
}

export function suggestSystem(lang, register) {
  return `You suggest useful phrases for an English-speaking adult learning ${lang.name} to talk with locals in a given situation.

Suggest phrases a learner would genuinely say or need in that situation. Short and useful beats long and complete ("one more time", "turn left" are fine). Make them varied: questions, requests, replies. Do not repeat or closely paraphrase any phrase the learner already has.

Translate each the way a friendly native speaker would actually say it. Register: ${registerRule(lang, register)}

Match the requested level: mostly at that level, some one level below or above.

For each phrase, english is the English phrase, and the remaining fields are its translation:
${fieldRules(lang)}`;
}

export function translateUser(english) {
  return `English: ${english}`;
}

export function clarifyUser({ english, currentTargetText, currentRomanization, history, clarification }) {
  const lines = [`Original English: ${english}`];
  for (const turn of history) {
    lines.push(`Earlier clarification: ${turn.clarification}\nTranslation it produced: ${turn.targetText}`);
  }
  lines.push(
    `Translation shown now: ${currentTargetText}${currentRomanization ? ` (${currentRomanization})` : ""}`,
    `Clarification: ${clarification}`,
  );
  return lines.join("\n\n");
}

export function suggestUser({ category, level, existing, count }) {
  const have = existing.length ? existing.map((e) => `- ${e}`).join("\n") : "(none yet)";
  return `Situation: ${category}
Level: ${level} on the 1–6 scale
Number of phrases: ${count}

Phrases the learner already has (do not repeat these or close paraphrases):
${have}`;
}
