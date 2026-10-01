// Language configurations matching the iOS app's Language model
const LANGUAGES = {
  "zh-CN": { name: "Mandarin Chinese", hasPronunciation: true, pronunciationName: "pinyin with tone marks" },
  "ja": { name: "Japanese", hasPronunciation: true, pronunciationName: "romaji" },
  "ko": { name: "Korean", hasPronunciation: true, pronunciationName: "romanized Korean (Revised Romanization)" },
  "es": { name: "Spanish", hasPronunciation: false },
  "fr": { name: "French", hasPronunciation: false },
  "de": { name: "German", hasPronunciation: false },
  "it": { name: "Italian", hasPronunciation: false },
  "pt-BR": { name: "Brazilian Portuguese", hasPronunciation: false },
  "ru": { name: "Russian", hasPronunciation: true, pronunciationName: "romanized Russian (transliteration)" },
  "ar": { name: "Arabic", hasPronunciation: true, pronunciationName: "romanized Arabic (transliteration)" },
  "hi": { name: "Hindi", hasPronunciation: true, pronunciationName: "romanized Hindi (transliteration)" },
  "th": { name: "Thai", hasPronunciation: true, pronunciationName: "romanized Thai (transliteration)" },
  "vi": { name: "Vietnamese", hasPronunciation: false },
  "id": { name: "Indonesian", hasPronunciation: false },
  "tr": { name: "Turkish", hasPronunciation: false },
  "nl": { name: "Dutch", hasPronunciation: false },
  "pl": { name: "Polish", hasPronunciation: false },
  "sv": { name: "Swedish", hasPronunciation: false },
  "uk": { name: "Ukrainian", hasPronunciation: true, pronunciationName: "romanized Ukrainian (transliteration)" },
  "el": { name: "Greek", hasPronunciation: true, pronunciationName: "romanized Greek (transliteration)" },
};

function buildSystemPrompt(langConfig, formality) {
  const formalityInstruction = formality === "formal"
    ? `Use formal/polite ${langConfig.name}, as you would with elders or in professional settings.`
    : `Use everyday, colloquial speech - the way a native speaker would naturally say it in casual conversation.`;

  if (langConfig.hasPronunciation) {
    return `You are a ${langConfig.name} language translation assistant. Translate English phrases into ${langConfig.name}. ${formalityInstruction}

Also provide a literal word-by-word translation to help learners understand the sentence structure.

Return JSON only, no markdown, no code blocks, just raw JSON:
{"targetText": "translation in native script here", "pronunciation": "${langConfig.pronunciationName} here", "literal": "word by word literal translation"}`;
  } else {
    return `You are a ${langConfig.name} language translation assistant. Translate English phrases into ${langConfig.name}. ${formalityInstruction}

Also provide a literal word-by-word translation to help learners understand the sentence structure.

Return JSON only, no markdown, no code blocks, just raw JSON:
{"targetText": "translation here", "literal": "word by word literal translation"}`;
  }
}

var index_default = {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type",
        },
      });
    }
    if (request.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }
    try {
      const { english, formality, targetLanguage } = await request.json();
      if (!english || typeof english !== "string") {
        return new Response(JSON.stringify({ error: "Missing 'english' field" }), {
          status: 400,
          headers: { "Content-Type": "application/json" },
        });
      }

      const langCode = targetLanguage || "zh-CN";
      const langConfig = LANGUAGES[langCode];
      if (!langConfig) {
        return new Response(JSON.stringify({ error: `Unsupported language: ${langCode}` }), {
          status: 400,
          headers: { "Content-Type": "application/json" },
        });
      }

      const systemPrompt = buildSystemPrompt(langConfig, formality);

      const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": env.ANTHROPIC_API_KEY,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-20250514",
          max_tokens: 256,
          system: systemPrompt,
          messages: [{ role: "user", content: english }],
        }),
      });
      if (!anthropicResponse.ok) {
        const errorData = await anthropicResponse.text();
        console.error("Anthropic error:", errorData);
        return new Response(JSON.stringify({ error: "Translation service error" }), {
          status: 502,
          headers: { "Content-Type": "application/json" },
        });
      }
      const anthropicData = await anthropicResponse.json();
      const translationText = anthropicData.content[0].text;
      let translation;
      try {
        translation = JSON.parse(translationText);
      } catch (e) {
        console.error("Failed to parse Claude response:", translationText);
        return new Response(JSON.stringify({ error: "Failed to parse translation" }), {
          status: 500,
          headers: { "Content-Type": "application/json" },
        });
      }

      // Ensure consistent response shape
      const response = {
        targetText: translation.targetText || "",
        pronunciation: translation.pronunciation || "",
        literal: translation.literal || "",
      };

      return new Response(JSON.stringify(response), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    } catch (error) {
      console.error("Worker error:", error);
      return new Response(JSON.stringify({ error: "Internal server error" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }
  },
};
export { index_default as legacy };
