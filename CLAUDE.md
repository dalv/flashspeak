# CLAUDE.md

FlashSpeak is an iOS SwiftUI app for learning spoken phrases. The user speaks English, it is transcribed on-device, translated colloquially (Claude via a Cloudflare Worker), spoken back, and saved for review as flashcards and hands-free audio recall.

**We are mid-overhaul on the `overhaul` branch.**
- Target spec: `dev-docs/PRD.md`
- How the app worked before the overhaul: `dev-docs/current-state.md`
- Progress and next steps: `dev-docs/progress.md`
- Decisions and why: `dev-docs/decisions/`

## Repo

- `FlashSpeak/`: the iOS app. `FlashSpeak.xcodeproj` uses a file-system-synchronized group, so new files under `FlashSpeak/` join the target automatically. Never hand-edit `project.pbxproj`.
- `cloudflare-worker/src/index.js`: the AI proxy. It holds `ANTHROPIC_API_KEY` (and later the TTS key) as Worker secrets. The app never holds an API key.
- `FlashSpeak/Services/APIConfig.swift`: gitignored but required to build; it defines `APIConfig.translationEndpoint`. Never print its contents. `APIConfig.swift.template` is stale.
- `docs/`: static App Store support and privacy pages. Don't move or rename them (their URLs are live). Planning docs go in `dev-docs/`.

## Build and test

- Build, run and test with the XcodeBuildMCP tools: project `FlashSpeak.xcodeproj`, scheme `FlashSpeak`, simulator iPhone 17 Pro.
- There is no test target yet. Phase 2 adds a small one (Swift Testing) covering only the pure logic: the FSRS scheduling with two buttons, duplicate detection, and the phrase migration. After that, run tests after every change.
- Worker changes: test locally with `wrangler dev`. Never deploy the Worker without asking me.

## Architecture

- **Deployment target: iOS 26** (decided). Use iOS 26 APIs freely: SpeechAnalyzer for transcription, Liquid Glass, current SwiftUI. No availability checks for older iOS.
- **Supported languages: Mandarin Chinese, Indonesian, Korean, Japanese only.** The other ~16 languages in the legacy code are being removed. Their phrases stay in iCloud but are hidden.
- **Text-to-speech: Apple's built-in voices (AVSpeechSynthesizer) for this release.** English is always a male voice; the target language is always a female voice. Prefer Enhanced/Premium voices when installed. Put TTS behind a protocol, because premium voices through the Worker come in a later release.
- **Services:** legacy code uses `X.shared` singletons called directly from views. New code puts each service behind a protocol, injects it through the SwiftUI environment, and provides a fake for Previews and tests. Add no new singletons; replace old ones as each area is rebuilt.
- **Persistence:** SwiftData synced through CloudKit (`iCloud.com.vladtamas.FlashSpeak`).
  - Every `@Model` property needs a default value or must be optional; `@Attribute(.unique)` is not allowed.
  - CloudKit production schema changes are ADDITIVE ONLY: never rename or remove a property or model.
  - All languages share one store, filtered by `languageCode`.
- **Languages** are defined in two places that must stay in sync: `Language.allLanguages` in `FlashSpeak/Models/Language.swift` and the `LANGUAGES` map in the Worker. A code the Worker doesn't know returns a 400.
- **Translation flow:** speech → `TranslationService` → Worker (builds the per-language prompt, calls Claude) → `{targetText, pronunciation, literal}` → `Phrase` → TTS.
- **Spaced repetition:** two rating buttons (Hard / Easy) is a deliberate product choice. Keep two buttons when moving from SM-2 to FSRS (Hard maps to FSRS Again, Easy to Good). The legacy one-character-per-tap hanzi reveal is dropped.
- **Monetization:** StoreKit 2 (`com.flashspeak.pro.{monthly,yearly,lifetime}`, local config in `Products.storekit`). `UsageManager` gives free users 3 translations per day. **DEBUG builds force `isSubscribed = true`**, so test the paywall and limit in Release or with the debug toggle.
- **Notifications:** `NotificationManager` schedules the daily reminder; tapping it posts `.navigateToPractice`.

## Rules

- No API keys in the app, ever. All AI and TTS calls go through the Worker.
- No hardcoded colours, fonts or spacing. Use the DesignSystem tokens (see `dev-docs/design-system.md`).
- Every new view has a `#Preview` with realistic sample data in Mandarin, Indonesian, Korean and Japanese.
- Liquid Glass only on controls and navigation, never on content cards.
- Don't delete legacy code until its replacement works and I've confirmed it.
- If the PRD doesn't cover a decision, ask me. Don't guess.

## Workflow

- Use plan mode first for anything touching more than 2 files.
- After a change: build, run the tests, and screenshot the affected screen in the simulator.
- At the end of each phase, update `dev-docs/progress.md` and add a decision record for any choice made.
