# 0004. Apple voices for this release

- Status: Accepted
- Date: 2026-09-29

## Context

Premium voice services (ElevenLabs, Azure, OpenAI) sound better but add cost, API keys, audio storage and caching. Apple's built-in voices are free, instant and work offline.

## Decision

Use Apple's built-in voices (AVSpeechSynthesizer) for this release.

- English is always one male voice. The target language is always one female voice per language.
- Use Enhanced or Premium voices when installed. If only the basic voice is present, show a one-time tip explaining how to download the better one.
- Put TTS behind a protocol so a premium provider can be swapped in later.

## Consequences

- No audio files to generate, store or sync in this release.
- Slow and word-by-word playback use the speaking rate and the word positions that Apple's speech engine reports.
- A premium provider comes in a later release, called through the Worker and picked per language after a blind listening test.

Source: [PRD, Speech and audio spec](../PRD.md#speech-and-audio-spec)
