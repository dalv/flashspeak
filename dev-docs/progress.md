# Progress

Tracks the five build phases from the [PRD](PRD.md#milestones-and-open-questions). Update this at the end of each phase, and record any choice made in [decisions/](decisions/).

Status values: Not started · In progress · Done

| Phase | Status |
| --- | --- |
| 1. Prove the core | Not started |
| 2. Foundations | In progress |
| 3. Capture | In progress |
| 4. Review | Not started |
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

- [~] AI proxy: v2 endpoints (translate, clarify, suggest, flag, config) built and tested locally, not deployed; App Attest and server-side free limit wait for the App Store release (0010)
- [x] Extended schema: additive Phrase fields, ReviewLog, migration; local store for now (CloudKit after the membership renewal)
- [x] App skeleton: module folders, `AppDependencies` (live / preview / test), services behind protocols with fakes; the legacy UI still runs behind `RootView`
- [x] Design tokens: `FlashSpeak/DesignSystem/` and the component gallery, awaiting design review ([design-system.md](design-system.md), [0012](decisions/0012-bundle-noto-cjk-fonts.md), [0013](decisions/0013-dark-mode-palette.md))
- [ ] Claude Code setup: CLAUDE.md, build and test tools, skills
- [x] Test target `FlashSpeakTests` (Swift Testing): FSRS, duplicates, set level, migration, repository, usage and settings

## 3. Capture

Status: In progress (Part A built; at Checkpoint A)

- [x] Home (Audio recall, Flashcards and the menu open placeholders until Milestone 3)
- [~] New phrase: speak and type done; suggest in Part B
- [x] Result card, with Clarify ([0017](decisions/0017-clarify-and-capture-layout.md))
- [ ] Duplicate detection
- [ ] Levels
- [ ] Free limit and paywall

## 4. Review

Status: Not started

- [ ] Flashcards with FSRS
- [ ] Audio recall with background playback
- [ ] Manage cards
- [ ] Settings
- [ ] Reminders

## 5. Migrate and ship

Status: Not started

- [ ] Schema upgrade for existing phrases
- [ ] Subscriber carry-over
- [ ] TestFlight with a few learners per language
- [ ] App Store update

## Next steps

- **Checkpoint A (Milestone 2):** review Home, New phrase, Result and Clarify. DEBUG launch arguments: `-demo home|speak|listening|type|result|clarify|clarifyReply` with `-demoLanguage zh-CN|id|ko|ja` open a screen with sample data; `-legacyUI` opens the old app.
- Then Part B: duplicates, Suggest, Paywall, Onboarding.
- **Checkpoint 1:** run the Worker with a key (`cloudflare-worker/.dev.vars`) and review real translations and clarifications in all four languages.

- Review the component gallery (light, dark, accessibility text) and the proposed dark palette.
- Start Phase 1.
