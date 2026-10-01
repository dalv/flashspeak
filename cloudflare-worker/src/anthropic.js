import Anthropic from "@anthropic-ai/sdk";

// Model and settings for v2. Sonnet per architecture.md (latency target:
// speech to playback under 5 s). Adaptive thinking at low effort keeps
// simple translations fast and still lets the model think on clarifications.
export const MODEL = "claude-sonnet-5-5";
const EFFORT = "low";
const MAX_TOKENS = 4000;

/** Thrown for failures the router turns into HTTP errors. */
export class UpstreamError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

/**
 * One Messages API call with structured JSON output.
 * Returns the parsed object, which matches `schema`.
 */
export async function generateJSON(env, { system, user, schema }) {
  if (!env.ANTHROPIC_API_KEY) {
    console.error("ANTHROPIC_API_KEY is not set (Worker secret, or .dev.vars locally)");
    throw new UpstreamError(503, "Translation service is not configured");
  }
  const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });

  let response;
  try {
    response = await client.beta.messages.create({
      model: MODEL,
      max_tokens: MAX_TOKENS,
      output_config: { effort: EFFORT, format: { type: "json_schema", schema } },
      // On a safety decline, re-run on Anthropic's recommended fallback model.
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      system,
      messages: [{ role: "user", content: user }],
    });
  } catch (error) {
    if (error instanceof Anthropic.RateLimitError) {
      throw new UpstreamError(503, "The translation service is busy. Try again in a moment.");
    }
    if (error instanceof Anthropic.APIError) {
      console.error("Anthropic API error", error.status, error.message);
      throw new UpstreamError(502, "Translation service error");
    }
    throw error;
  }

  if (response.stop_reason === "refusal") {
    console.error("Refusal", response.stop_details?.category);
    throw new UpstreamError(422, "This phrase couldn't be translated.");
  }
  if (response.stop_reason === "max_tokens") {
    throw new UpstreamError(502, "The translation was cut off. Try a shorter phrase.");
  }

  const text = response.content
    .filter((block) => block.type === "text")
    .map((block) => block.text)
    .join("");
  try {
    return JSON.parse(text);
  } catch {
    console.error("Unparseable structured output", text.slice(0, 500));
    throw new UpstreamError(502, "Failed to parse translation");
  }
}
