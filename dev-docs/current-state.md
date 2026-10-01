# Current state (before the overhaul)

How the app and the Worker work at the start of the overhaul (`overhaul` branch, commit 4431664). The target is in the [PRD](PRD.md); the proposed structure is in [architecture.md](architecture.md).

## Summary and history

FlashSpeak is a SwiftUI app: speak an English phrase, it is transcribed, translated by Claude through a Cloudflare Worker, spoken with Apple TTS, and saved as a flashcard for two-button spaced repetition.

The git history has two very different versions:

| | Version 1.0 (9308871, Dec 2025) | Current code (4e44fbd, Sep 29 2026) |
| --- | --- | --- |
| Project | `FlashSpeak - Chinese` | `FlashSpeak` |
| Bundle ID | `com.vladtamas.FlashSpeak-Chinese` | `com.vladtamas.FlashSpeak` |
| Languages | Mandarin only | About 20 |
| Storage | Local SwiftData, **no CloudKit** | SwiftData + CloudKit `iCloud.com.vladtamas.FlashSpeak` |
| Phrase fields | `id`, `hanzi`, `pinyin`, ... | `targetText`, `pronunciation`, `languageCode`, no `id` |
| Worker response read | `{hanzi, pinyin, literal}` | `{targetText, pronunciation, literal}` |
| Product IDs in code | `com.flashspeak.chinese.{monthly,yearly29,lifetime}` | `com.flashspeak.pro.{monthly,yearly,lifetime}` |
| TTS | `ChineseTTSService` | `TTSService` (any language) |

The current code is almost certainly unreleased. The PRD says the live app supports Mandarin and Indonesian, which matches neither version. See [Unknowns](#unknowns-to-check-before-an-app-store-release).

For now the app is built locally and run on the developer's own phone; the developer licence has expired, so App Store questions wait.

## Build facts

- Deployment target iOS 18.1 (to become 26), `SWIFT_VERSION = 5.0`, iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`), version 1.0 (1).
- Info.plist: microphone and speech recognition usage strings; `UIBackgroundModes = remote-notification` (for CloudKit pushes).
- Entitlements: `aps-environment = development`, iCloud with CloudKit, container `iCloud.com.vladtamas.FlashSpeak`.
- The scheme points at `FlashSpeak/Products.storekit` for local StoreKit testing.
- No test target, no linter. SwiftFormat runs through a Claude Code hook (`.claude/settings.json`), with no `.swiftformat` config.
- `FlashSpeak/Services/APIConfig.swift` is gitignored and required; it defines `APIConfig.translationEndpoint`. `APIConfig.swift.template` is stale (shows `anthropicAPIKey`).
- Build with XcodeBuildMCP (scheme `FlashSpeak`, iPhone 17 Pro simulator), not the old "iPhone 16" `xcodebuild` command.
- Odd filename: `FlashSpeak/Services/ NotificationManager.swift` starts with a space.

**Local-device builds without a paid membership** sign with a free Personal Team. That team cannot use the iCloud/CloudKit, push (`aps-environment`) or App Attest capabilities, profiles expire after 7 days, and StoreKit only works with the local `.storekit` file. The current entitlements will not sign until iCloud and push are removed or the membership is renewed.

## Screens and flows

- **Home** (`HomeView`): title, the current language as a button that cycles through "my languages", **New Phrase** and **Practice** buttons, and a menu with Manage Cards and Settings. Practice is opened by a notification tap through the deprecated `NavigationLink(isActive:)`.
- **New phrase** (`NewPhraseView`): a state machine idle → listening → translating → result / error. Idle shows the mic button, "N free translations left today" for free users, an Upgrade button at the limit, and a text field to type instead. Listening shows a pulsing circle and the live transcript; "Done Speaking" stops and translates. Result shows English, pronunciation (only if the language has a guide), the target text, the literal gloss, a speaker button, **Retry** and **Save**; audio auto-plays if the setting is on. Retry re-translates the same English and is always visible, as the original spec asked. Save inserts a `Phrase`, counts one translation and dismisses.
- **Practice** (`PracticeView`): loads due phrases for the current language once, on appear. English → "Tap to reveal". Languages with a pronunciation guide: show pronunciation and gloss (auto-play), then "Reveal characters" shows the script **one character per tap**, then Hard / Easy. Languages without a guide: show the answer and gloss, then Hard / Easy. Empty state: "All caught up!" with the next review time.
- **Manage cards** (`ManageCardsView`): current-language phrases, newest first; each row shows English, pronunciation, target, a play button and "Next review: ...". Swipe to delete, plus "Delete All Cards" with an alert. Both are hard deletes.
- **Settings** (`SettingsView`): language (to `LanguageSettingView`), auto-play, formality (Informal / Formal, one global value), daily reminder with a time, subscription (Pro badge or Upgrade, Restore Purchases).
- **Languages** (`LanguageSettingView`, `AddLanguageView`): "my languages" list; tap to make active, swipe to remove (only with more than one), and choose "Remove Language Only" or "Remove Language & Cards". Add searches all 20.
- **Paywall** (`PaywallView`): "Upgrade to Pro / Unlock unlimited translations", today's usage, products from StoreKit with their prices, renewal terms text.

## Data model

### Current `Phrase` (`FlashSpeak/Models/Phrase.swift`)

The only `@Model`. All languages share one store, filtered by `languageCode`.

| Field | Type | Default | Notes |
| --- | --- | --- | --- |
| `englishText` | `String` | `""` | |
| `targetText` | `String` | `""` | Native script |
| `pronunciation` | `String` | `""` | Romanization; empty for languages without a guide |
| `literalTranslation` | `String` | `""` | Word-by-word gloss as one string |
| `languageCode` | `String` | `"zh-CN"` | |
| `createdAt` | `Date` | `Date()` | |
| `lastReviewedAt` | `Date?` | `nil` | |
| `nextReviewAt` | `Date` | `Date()` | New phrases are due at once |
| `easeFactor` | `Double` | `2.5` | SM-2 |
| `interval` | `Double` | `0` | Days |
| `repetitions` | `Int` | `0` | SM-2 |

There is no stable ID (only SwiftData's `persistentModelID`), no review history, no soft delete, and no `updatedAt`.

### Version 1.0 `Phrase` (for comparison)

`id: UUID`, `englishText`, `hanzi`, `pinyin`, `literalTranslation`, `createdAt`, `lastReviewedAt: Date?`, `nextReviewAt`, `easeFactor`, `interval`, `repetitions`. Non-optional properties with no defaults; no CloudKit; no `languageCode`.

### Preferences (`@AppStorage`, device-local, not synced)

| Key | Default | Owner |
| --- | --- | --- |
| `autoPlayAudio` | `true` | SettingsManager |
| `formality` | `"informal"` (or `"formal"`) | SettingsManager |
| `notificationsEnabled` | `false` | SettingsManager |
| `notificationHour` / `notificationMinute` | `9` / `0` | SettingsManager |
| `currentLanguageCode` | `"id"` | SettingsManager |
| `myLanguageCodes` | `["id","zh-CN"]` (JSON string) | SettingsManager |
| `translationsToday` | `0` | UsageManager |
| `lastTranslationDate` | `""` (`yyyy-MM-dd`) | UsageManager |

### Languages (`FlashSpeak/Models/Language.swift`)

`Language(code, name, flag, ttsCode, hasPronunciationGuide)`; 20 entries: zh-CN, ja, ko, es, fr, de, it, pt-BR, ru, ar, hi, th, vi, id, tr, nl, pl, sv, uk, el. The same codes are in the Worker's `LANGUAGES` map.

## Services

All are `X.shared` singletons called directly from views, except `SpeechRecognitionService`, which each view creates as a `@StateObject`.

- **SpeechRecognitionService:** `SFSpeechRecognizer(en-US)` with an `AVAudioEngine` tap and partial results. It does **not** set `requiresOnDeviceRecognition`, so audio may be sent to Apple's servers. It sets the audio session to `.record` / `.measurement` and deactivates it when done. Nothing is recorded to a file.
- **TranslationService:** POSTs `{english, formality, targetLanguage}` to `APIConfig.translationEndpoint` and parses `targetText`, `pronunciation`, `literal`. No timeout, retry or offline handling.
- **TTSService:** one `AVSpeechSynthesizer`. Picks the voice with `AVSpeechSynthesisVoice(language: ttsCode)`, so no gender or quality choice; rate fixed at `0.45`. Sets the audio session to `.playback` on every `speak`, which competes with the speech service's session. `warmUp()` speaks a silent utterance at launch.
- **SpacedRepetitionService:** simplified SM-2 with two ratings. Hard: repetitions = 0, interval = 1 minute, ease − 0.2 (min 1.3). Easy: repetitions + 1; interval 1 day, then 6 days, then `interval × ease`; ease + 0.1 (max 3.0). `nextReviewAt = now + interval`. Because Practice loads the due list once, a card rated Hard is not seen again in the same session.
- **UsageManager:** 3 free translations a day, counted locally, reset at the local date change. **Counted on Save, not on translate**, so retries and unsaved translations are unlimited, and reinstalling resets the count.
- **StoreManager:** StoreKit 2, products `com.flashspeak.pro.{monthly,yearly,lifetime}`, a transaction listener, restore through `AppStore.sync()`. `isSubscribed` is true for **any** verified, unrevoked current entitlement, whatever the product ID. **DEBUG builds force `isSubscribed = true`.**
- **NotificationManager:** one repeating daily notification ("How do you say: ...?") with a random phrase picked when it is scheduled, so the text never changes. `refreshNotification` is never called. Settings passes phrases from **all** languages but shows the current language's flag. Tapping it posts `.navigateToPractice`.
- **SettingsManager:** the `@AppStorage` keys above, plus "my languages" helpers.

## Worker (`cloudflare-worker/src/index.js`)

- There is no `wrangler.toml` in the repo, so the Worker's name, routes and secrets are not recorded and `wrangler dev` cannot run as-is. The file looks like bundled output copied from the Cloudflare dashboard (`var index_default = ...; export { index_default as default }`).
- **Request:** `POST` with JSON `{english, formality, targetLanguage}`. `targetLanguage` defaults to `"zh-CN"` and `formality` is `"formal"` or anything else (treated as informal). `OPTIONS` returns CORS headers allowing any origin.
- **Response 200:** `{targetText, pronunciation, literal}`, with missing fields as `""`.
- **Errors:** 405 not POST; 400 missing `english` or unknown language; 502 Anthropic error; 500 unparseable Claude output or any other error.
- **Model call:** `claude-sonnet-4-20250514`, `max_tokens: 256`, `anthropic-version: 2023-06-01`, system prompt below, the English as the only user message. JSON is requested in the prompt only, so a fenced or chatty reply fails with 500.
- **Security:** no authentication, rate limit or usage counting. Anyone with the URL can spend the Anthropic key.

### The prompt (verbatim)

```js
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
```

`pronunciationName` for the four supported languages: zh-CN "pinyin with tone marks", ja "romaji", ko "romanized Korean (Revised Romanization)"; id has none. Compared with the [PRD](PRD.md#translation-quality-spec), the prompt has no per-language register rules, no kana reading for Japanese, no alternative, usage note or level, and no version number.

## From `ToDo - old.md`, still relevant

`ToDo - old.md` is the original Chinese-only spec and Q&A.

- **Retry stays visible after a successful translation**, because Claude may give a better version on a second try. This becomes the PRD's "Try another version".
- **Never store the English recording**, not even temporarily. SpeechAnalyzer streaming keeps that true.
- **A retry action when translation fails.**
- **Two buttons, Hard and Easy**, are the user's preference (now [decision 0005](decisions/0005-two-button-fsrs.md)).
- Offline translation was deferred; the PRD now queues new translations until back online.
- Dropped: the one-character-per-tap hanzi reveal ([0005](decisions/0005-two-button-fsrs.md)) and local-only storage ([0001](decisions/0001-keep-icloud-for-now.md)).

## What makes the migration tricky

**Now (local builds):**

- CloudKit and push can't be signed with a Personal Team, so the app needs a local-only store mode until the membership is renewed.
- No stable ID on `Phrase`. Adding `id` to existing rows needs a one-time backfill, and two devices could backfill different UUIDs for the same row.
- There is no review history to convert to FSRS; only `interval`, `repetitions`, `easeFactor` and `nextReviewAt`. Cards are seeded, not replayed.
- Phrases in the 16 dropped languages must be hidden, never deleted (CloudKit, [0003](decisions/0003-four-languages-only.md)).
- `formality` (informal/formal, global) has to map to the PRD's register (casual/neutral/polite, per language).
- Preferences are device-local `@AppStorage`, so they don't follow the user to a second device.
- Two places define the language list (app and Worker) and must change together.
- Hard deletes today; soft deletes with a 30-day purge are new behaviour.

**Before an App Store release:**

- **Bundle ID.** If the live app is `com.vladtamas.FlashSpeak-Chinese`, the current `com.vladtamas.FlashSpeak` is a different app, and none of the live users, purchases or data carry over. The PRD requires keeping the bundle ID.
- **1.0 local data.** 1.0 users have a local store with `hanzi`/`pinyin`. Opening it with the current model would drop those columns and lose the text, unless the model maps them with `@Attribute(originalName:)`. `id` was also removed.
- **Default language.** `currentLanguageCode` defaults to `"id"`, so a Chinese-only 1.0 user would land on an empty Indonesian set.
- **Product IDs.** The code's `com.flashspeak.pro.*` IDs don't match `Products.storekit` or 1.0 (`com.flashspeak.chinese.*`). Existing subscribers still read as Pro (any entitlement counts), but the paywall would show no products if the `pro` IDs don't exist in App Store Connect.
- **The live Worker.** 1.0 needs `{hanzi, pinyin}`; the repo Worker returns `{targetText, pronunciation}`. Deploying one breaks the other's app, so the Worker must stay backward compatible.
- **CloudKit schema.** If the current code never shipped, the production schema may not exist yet. Deploying it makes it permanent (additive only from then on), so it should be right before the first deploy.

## Unknowns to check before an App Store release

These need a renewed Apple Developer membership (and the updated licence agreement accepted) and a `wrangler login`.

| Question | How to check |
| --- | --- |
| Which version is live, with which bundle ID? | App Store Connect, or Spaceship: `Spaceship::ConnectAPI::App.all` and `get_app_store_versions` (fastlane's gem, API key at `$APP_STORE_CONNECT_API_KEY_PATH`) |
| Which in-app purchase product IDs exist? | App Store Connect, In-App Purchases and Subscriptions |
| What code is deployed on the Worker? | `wrangler deployments list --name <worker>` and the dashboard's source view; compare with `cloudflare-worker/src/index.js` |
| Does a production CloudKit schema exist for the container? | CloudKit Console, `iCloud.com.vladtamas.FlashSpeak`, Production schema |
