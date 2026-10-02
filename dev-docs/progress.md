# Progress

Tracks the five build phases from the [PRD](PRD.md#milestones-and-open-questions). Update this at the end of each phase, and record any choice made in [decisions/](decisions/).

Status values: Not started · In progress · Done

| Phase | Status |
| --- | --- |
| 1. Prove the core | Not started |
| 2. Foundations | In progress |
| 3. Capture | Done |
| 4. Review | Done (device test pending) |
| 5. Migrate and ship | Not started |

## 1. Prove the core

Status: Not started

- [ ] Pick the best Apple voices per language (male English, female target)
- [ ] Check slow and word-by-word playback
- [ ] First version of the translation prompt
- [ ] Translation evaluation set (50 phrases per language)
- [x] Raise the minimum iOS version to 26 (2026-10-01; the legacy app builds unchanged)

## 2. Foundations

Status: In progress

- [~] AI proxy: v2 endpoints (translate, clarify, suggest, flag, config) deployed to `flashspeak-api` (2026-10-02), placed in aws:us-east-1; App Attest and server-side free limit wait for the App Store release (0010)
- [x] Extended schema: additive Phrase fields, ReviewLog, migration; local store for now (CloudKit after the membership renewal)
- [x] App skeleton: module folders, `AppDependencies` (live / preview / test), services behind protocols with fakes; the legacy UI still runs behind `RootView`
- [x] Design tokens: `FlashSpeak/DesignSystem/` and the component gallery, awaiting design review ([design-system.md](design-system.md), [0012](decisions/0012-bundle-noto-cjk-fonts.md), [0013](decisions/0013-dark-mode-palette.md))
- [ ] Claude Code setup: CLAUDE.md, build and test tools, skills
- [x] Test target `FlashSpeakTests` (Swift Testing): FSRS, duplicates, set level, migration, repository, usage and settings

## 3. Capture

Status: Done (Parts A and B built; awaiting your review on device)

- [x] Home
- [x] New phrase: speak, type and suggest
- [x] Result card, with Clarify ([0017](decisions/0017-clarify-and-capture-layout.md))
- [x] Duplicate detection (exact and near, on-device embeddings)
- [x] Levels (per-phrase level, set level from the last 50)
- [x] Free limit and paywall
- [x] Onboarding (first language)
- [x] Checkpoint 1: real translations and clarifications from the local Worker in all four languages (2026-10-01)
- [ ] Audio not heard in the simulator; check voices and sound on a device

## 4. Review

Status: Done in the simulator (2026-10-01); device test pending

- [x] Flashcards with FSRS: Hard/Easy with next-interval labels, Hard repeats in the session, daily new-card limit, listening-first option, "All caught up" ([0005](decisions/0005-two-button-fsrs.md), [0021](decisions/0021-phase-4-interpretations.md))
- [x] Audio recall with background playback: setup, hands-free session, lock screen controls, interruptions, summary; practice only ([0019](decisions/0019-audio-recall-is-practice-only.md))
- [x] Manage cards: sections, search, sort, delete with Undo, hide presets, delete all, full card with Clarify, another version and edit
- [x] Preset categories: five categories in four languages, corrections by content version ([0015](decisions/0015-preset-categories.md), [0018](decisions/0018-preset-content-generated-then-reviewed.md)); added to flashcards and audio recall separately, with confirmations ([0022](decisions/0022-preset-review-sets.md))
- [ ] Preset content checked by a native reviewer per language (generated, `reviewed: false`; doubtful items listed in 0018)
- [x] Settings: language, register, level, new cards per day, playback and recall options, better-voices tip, Pro and restore, CSV export ([0020](decisions/0020-export-as-csv.md)), delete all, DEBUG free-user switch
- [x] Reminders: daily notification with a phrase to recall; tapping it opens Flashcards
- [ ] On a device: voices and sound (silent in the simulator), audio recall with the screen locked, lock screen controls, calls and headphones, reminders, microphone

## 5. Migrate and ship

Status: Not started

- [ ] Schema upgrade for existing phrases
- [ ] Subscriber carry-over
- [ ] TestFlight with a few learners per language
- [ ] App Store update

## Next steps

- **Your review** of the Phase 4 screens and the choices in [0021](decisions/0021-phase-4-interpretations.md). DEBUG launch arguments open any screen with sample data: `-demo <name>` with `-demoLanguage zh-CN|id|ko|ja`. Names: home, onboarding, paywall, speak, listening, type, suggest, suggested, result, duplicate, clarify, clarifyReply, flashcards, flashcardBack, caughtUp, recall, recallThinking, recallAnswer, manage, card, presets, presetDetail, presetConfirm, settings. `-legacyUI` opens the old app. Translations hit the deployed Worker by default; `-localWorker` uses `wrangler dev` instead and `-fakeTranslation` uses canned samples.
- **Device test** (the list under Phase 4).
- **Native review** of the preset content and the translation evaluation set.
- **Phase 1 leftovers:** pick the best Apple voices per language, check slow and word-by-word playback on a device, the 50-phrase evaluation set.
- **Phase 5:** CloudKit on (after the membership renewal), migration on real 1.x data, subscriber carry-over, delete the legacy code once you confirm, Worker deploy (with your go-ahead), TestFlight.
- Review the component gallery (light, dark, accessibility text) and the proposed dark palette.
