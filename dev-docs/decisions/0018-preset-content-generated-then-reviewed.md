# 0018. Preset content is generated now and reviewed later

- Status: Accepted
- Date: 2026-10-01

## Context

Preset categories (0015) need content in four languages before a native reviewer is lined up (an open PRD question).

## Decision

- Generate every preset card with the Worker's own translation prompt and model (`cloudflare-worker/scripts/generate-presets.mjs`, run locally with the key in `.dev.vars`). A short note per item covers number readings (Mandarin 二/两, Japanese yon/nana/kyū, Sino-Korean and native Korean with counters) and asks for an example phrase on connector and question words.
- Ship it as `FlashSpeak/Presets/Content/presets.<lang>.json` with `contentVersion: 1` and `reviewed: false`. Neutral register. Numbers show digits on the front.
- Corrections bump `contentVersion`; on launch `PresetLibrary.applyCorrections` updates existing cards by item key and keeps their schedule and history.

## For the native reviewers

Items that looked doubtful on a first read:
- Korean "when" is -(으)면 and Japanese "when" is 〜たら (conditional forms). Consider (으)ㄹ 때 and 〜とき.
- Japanese "also" is それと (も is more typical).
- Some lone words carry polite endings: Korean 왜요?, 아직요; Japanese まだです.
- Mandarin pinyin spacing differs between day names (xīngqī yī, xīngqīsān).

## Consequences

- Presets work offline and cost nothing per user; generation cost a few cents once.
- Content can ship before review, but must be reviewed before the App Store release (progress.md tracks it).
