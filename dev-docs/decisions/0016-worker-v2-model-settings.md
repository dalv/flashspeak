# 0016. Worker v2 model settings

- Status: Accepted (to revisit after the evaluation set runs)
- Date: 2026-10-01

## Context

architecture.md calls for a current Sonnet for v2, structured output instead of "return raw JSON", and a speech-to-playback median under 5 seconds.

## Decision

- Model `claude-sonnet-5-5`, adaptive thinking at `output_config.effort: "low"`, so simple translations stay fast and clarifications can still think.
- Structured output via `output_config.format` (`json_schema`), one schema per endpoint, parsed and normalized by the Worker. Forced tool use isn't available on this model.
- Server-side `fallbacks: "default"` (beta `server-side-fallback-2026-07-01`): if a safety classifier declines a phrase, the API re-runs it on Anthropic's recommended fallback model instead of failing. A decline that still ends in a refusal returns 422.
- The legacy `POST /` keeps its old model and prompt (0008).

## Consequences

- Latency and quality must be checked on the evaluation set; effort can move to `medium` or the model to Opus per route if quality falls short.
- `npm test` covers request validation and normalization without API calls; quality needs a live run with a key in `.dev.vars`.

Source: [architecture.md, Worker changes](../architecture.md#worker-changes)
