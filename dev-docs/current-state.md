# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

FlashSpeak is an iOS 18.1+ SwiftUI app (iPhone and iPad) for learning phrases in a foreign language. The user speaks an English phrase, the app transcribes it on-device, translates it through a Cloudflare Worker that calls the Anthropic API, speaks the result with Apple TTS, and saves it as a flashcard for spaced-repetition practice. It began as a Chinese-only app ("FlashSpeak - Chinese", the old project that is now deleted in git) and now supports about 20 languages.

The repo has two deployable parts:
- `FlashSpeak/`: the iOS app. `FlashSpeak.xcodeproj` uses a file-system-synchronized group, so a new file under `FlashSpeak/` joins the target automatically, with no pbxproj edits.
- `cloudflare-worker/src/index.js`: the translation proxy. It keeps `ANTHROPIC_API_KEY` as a Worker secret (`env.ANTHROPIC_API_KEY`), so the app never holds an API key.

## Build

The project has no test target and no linter.

```bash
xcodebuild -project FlashSpeak.xcodeproj -scheme FlashSpeak \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

`FlashSpeak/Services/APIConfig.swift` is gitignored but required for the build. It defines `APIConfig.translationEndpoint` (the Worker URL). `APIConfig.swift.template` is stale: it still shows an old `anthropicAPIKey` field.

## Architecture

**Services are singletons** (`X.shared`) under `FlashSpeak/Services/`. Views call them directly; the app uses no dependency injection. `SpeechRecognitionService` is the exception: it is a `@MainActor` `ObservableObject` that each view creates for itself.

**Translation flow:** `SpeechRecognitionService` (SFSpeechRecognizer, fixed to en-US) → `TranslationService.translate(_:formality:targetLanguage:)`, which POSTs `{english, formality, targetLanguage}` to the Worker → the Worker builds a system prompt for that language and calls Claude → it returns `{targetText, pronunciation, literal}` → the app creates a `Phrase` → `TTSService.speak`.

**The language list lives in two places and must stay in sync:** `FlashSpeak/Models/Language.swift` (`Language.allLanguages`, with TTS locale codes and `hasPronunciationGuide`) and the `LANGUAGES` map in `cloudflare-worker/src/index.js` (the pronunciation/romanization name used in the prompt). A language code that the Worker does not know gets a 400 response.

**Persistence:** SwiftData with a single `@Model Phrase`, synced through CloudKit (`iCloud.com.vladtamas.FlashSpeak`, set up in `FlashSpeakApp.swift`). Because of CloudKit, every `Phrase` property needs a default value or must be optional, and `@Attribute(.unique)` is not allowed. Phrases for every language share one store and are filtered by `languageCode`. User preferences, including the current language and "my languages", are `@AppStorage` properties in `SettingsManager`.

**Spaced repetition:** `SpacedRepetitionService` uses a simplified SM-2 with only two ratings, Hard and Easy. The two-button design is deliberate; the user prefers it to Anki's four levels. Hard resets `repetitions` and schedules a review 1 minute later (a same-session retry). Easy steps the interval 1d → 6d → `interval * easeFactor`. `interval` is stored in days.

**Monetization:** `StoreManager` (StoreKit 2, with product IDs `com.flashspeak.pro.{monthly,yearly,lifetime}` and local config in `FlashSpeak/Products.storekit`) and `UsageManager` (a free limit of 3 translations per day). **In DEBUG builds `isSubscribed` is forced to `true`**, so paywall and limit behavior only shows up in Release builds.

**Notifications:** `NotificationManager` schedules a daily practice reminder. Tapping it posts `.navigateToPractice` through `NotificationCenter`, and `FlashSpeakApp` passes that to `HomeView` as a binding.

## Other

- `docs/` holds static pages (presumably for App Store support/privacy URLs).
- `ToDo - old.md` is the original product spec. It covers the intended UX: speech → translate → show pronunciation + native script → TTS; in practice, pinyin and audio first, then the hanzi revealed one character per tap, then Hard/Easy. The retry-translation button stays visible even after a successful translation.
