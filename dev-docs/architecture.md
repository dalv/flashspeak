# Architecture (proposal)

Status: **Agreed** (2026-10-01). Decisions taken while agreeing it are listed at the [end](#decisions), with records 0007–0011 in [decisions/](decisions/).

This describes how the overhauled app and Worker are structured. What the product does is in the [PRD](PRD.md); how the legacy app works is in [current-state.md](current-state.md).

## Constraints this design follows

- iOS 26 only ([0002](decisions/0002-ios-26-minimum.md)); four languages ([0003](decisions/0003-four-languages-only.md)); Apple voices behind a protocol ([0004](decisions/0004-apple-voices-for-this-release.md)); two-button FSRS ([0005](decisions/0005-two-button-fsrs.md)); the Worker as a small AI proxy ([0006](decisions/0006-extend-the-cloudflare-worker.md)).
- SwiftData + CloudKit: every property optional or defaulted, no unique constraints, relationships optional, schema changes additive only.
- **For now the app runs only on the developer's phone, signed with a free Personal Team.** That rules out CloudKit, push, App Attest and sandbox purchases until the membership is renewed, so each of those has a local fallback below.

## Modules

One app target for now ([0011](decisions/0011-modules-as-folders.md)). Each module is a folder under `FlashSpeak/` (the file-system-synchronized group picks new files up), arranged so it can become a local Swift package later.

| Module | Contains | Depends on |
| --- | --- | --- |
| `App` | `FlashSpeakApp`, `AppDependencies` (composition root), model container setup | Everything |
| `DesignSystem` | Tokens (colour, type, spacing), shared components (card, play button, level label) | Nothing |
| `Persistence` | `@Model` types, repositories, the migration step | Foundation, SwiftData |
| `Translation` | `TranslationClient`, request and response types, the Worker client | Persistence types |
| `Speech` | `TranscriptionService` (SpeechAnalyzer) | |
| `Audio` | `SpeechSynthesizer`, `VoiceCatalog`, `AudioSessionCoordinator`, `RecallPlayer` | |
| `Review` | `Scheduler` (FSRS), session building (due first, new-card limit) | Persistence types |
| `Capture` | `DuplicateDetector`, `EmbeddingProvider`, set-level calculation | Persistence types |
| `Entitlements` | `EntitlementService` (StoreKit), `UsageService` | |
| `Notifications` | `ReminderScheduler` | |
| `Features/<Screen>` | One folder per screen: Home, NewPhrase, AudioRecall, Flashcards, ManageCards, Settings, Paywall, Onboarding | Protocols from the modules above, DesignSystem |

**Rule:** features use protocols only. Only `App` creates concrete types. Pure logic (scheduler, duplicate normalization, set level, migration) has no SwiftUI, SwiftData context or I/O, so the Phase 2 test target can cover it directly.

Legacy files stay where they are until their replacement works and is confirmed, then they are deleted.

## Dependency injection

- `AppDependencies` holds one instance of each service, with three factories: `.live`, `.preview` (fakes with sample data in all four languages) and `.test`.
- Each service is exposed as an environment value declared with `@Entry`, for example `@Environment(\.translationClient)`. Previews call `.environment(\.translationClient, FakeTranslationClient())`.
- No new singletons. Long-lived services (audio session, recall player, entitlements) are created once in `App` and passed down.
- Observable state lives in `@Observable` view models per screen, created by the screen with the services it needs.

## Service protocols

Each protocol has a live implementation and a fake. Signatures are indicative; details are settled in the phase that builds them.

**Speech to text**

```swift
protocol TranscriptionService {
    /// Downloads the on-device English model if needed, reporting progress.
    func prepare() -> AsyncThrowingStream<Double, Error>
    /// Streams partial and final transcripts until stop() is called.
    func start() -> AsyncThrowingStream<Transcript, Error>
    func stop() async
}
```

Live: `SpeechAnalyzer` with en-US, fully on device, nothing written to disk.

**Translation**

```swift
protocol TranslationClient {
    func translate(_ request: TranslationRequest) async throws -> TranslationResult
    func suggest(_ request: SuggestionRequest) async throws -> [SuggestedPhrase]
    func flag(_ report: TranslationFlag) async throws
}
```

`TranslationResult` mirrors the v2 Worker response below, including `usage`. Live: `WorkerTranslationClient`. A typed error enum covers offline, limit reached (opens the paywall and keeps the phrase), server and decoding errors.

**Text to speech and audio**

```swift
enum VoiceRole { case english, target(Language) }
enum PlaybackSpeed { case natural, slow, wordByWord }

protocol SpeechSynthesizer {
    func speak(_ text: String, role: VoiceRole, speed: PlaybackSpeed) async
    var wordBoundaries: AsyncStream<Range<String.Index>> { get }
    func stop()
}

protocol VoiceCatalog {
    func voice(for role: VoiceRole) -> VoiceChoice   // male English, female target
    func hasHighQualityVoice(for language: Language) -> Bool   // for the one-time tip
}

protocol AudioSessionCoordinator {
    func activate(_ mode: AudioMode) throws   // .recording, .playback, .backgroundRecall
    var interruptions: AsyncStream<AudioInterruption> { get }
}

protocol RecallPlayer {   // audio recall loop
    func start(_ phrases: [Phrase], options: RecallOptions)
    func pause(); func resume(); func skip(); func stop()
    var events: AsyncStream<RecallEvent> { get }   // drives the screen and progress
}
```

Live: `AppleSpeechSynthesizer` (AVSpeechSynthesizer, rate per speed, word positions from the delegate), `AppleVoiceCatalog` (prefers Premium, then Enhanced), `RecallPlayer` with Now Playing and remote commands. Later: `WorkerVoiceSynthesizer` for premium voices, with no change to callers.

**Review**

```swift
enum Rating { case hard, easy }   // FSRS Again, Good

protocol Scheduler {
    func next(_ state: CardState, rating: Rating, now: Date) -> CardState
}
```

Pure and deterministic. `CardState` holds FSRS state, stability, difficulty, due date and lapses.

**Persistence**

```swift
protocol PhraseRepository {
    func phrases(in language: Language, sort: PhraseSort) throws -> [Phrase]
    func due(in language: Language, now: Date, newLimit: Int) throws -> [Phrase]
    func insert(_ phrase: Phrase) throws
    func softDelete(_ phrase: Phrase) throws
    func purgeDeleted(olderThan: Date) throws
}

protocol ReviewRepository {
    func append(_ review: ReviewLog) throws
}
```

Every query excludes soft-deleted rows and languages outside `Language.supported`.

**Capture**

```swift
protocol EmbeddingProvider { func embedding(for text: String) -> [Double]? }

protocol DuplicateDetector {
    func exactMatch(english: String, target: String?, in language: Language) throws -> Phrase?
    func nearMatches(english: String, in language: Language) throws -> [Phrase]
}
```

Exact matching uses one normalization function (case, punctuation, spaces), shared with suggestion filtering. Near matching uses `NLEmbedding` sentence embeddings, stored on the phrase.

**Entitlements, usage, reminders, settings**

```swift
protocol EntitlementService {
    var isPro: AsyncStream<Bool> { get }
    func products() async throws -> [Product]
    func purchase(_ product: Product) async throws -> Bool
    func restore() async throws
    func signedTransaction() async -> String?   // sent to the Worker
}

protocol UsageService {
    var remainingToday: Int? { get }   // from the last Worker response
    func update(from usage: Usage)
}

protocol ReminderScheduler {
    func schedule(at time: DateComponents, language: Language, phrases: [Phrase]) async throws
    func cancel()
}

protocol SettingsStore {
    var currentLanguage: Language { get set }
    func settings(for language: Language) -> LanguageSettings   // plain struct, stored in @AppStorage
    func update(_ settings: LanguageSettings, for language: Language)
}
```

## Data model changes (additive only)

No property or model is renamed or removed. Legacy fields stay in the schema even when unused.

### `Phrase`: new fields

| Field | Type | Default | Purpose |
| --- | --- | --- | --- |
| `id` | `UUID?` | `nil`, backfilled | Stable ID for sync and a future backend |
| `source` | `String` | `"legacy"` | spoken / typed / suggested / imported / legacy |
| `reading` | `String?` | `nil` | Kana reading for Japanese |
| `glossData` | `Data?` | `nil` | JSON word pairs for the expandable gloss; `literalTranslation` stays as the plain string |
| `alternative` | `String?` | `nil` | One alternative version |
| `usageNote` | `String?` | `nil` | "used with friends only" |
| `level` | `Int?` | `nil` | Internal 1–6 scale |
| `embedding` | `Data?` | `nil` | Sentence embedding for near-duplicate checks |
| `promptVersion` | `String?` | `nil` | Which Worker prompt produced it |
| `updatedAt` | `Date?` | `nil` | Last edit |
| `deletedAt` | `Date?` | `nil` | Soft delete; purged after 30 days |
| `fsrsState` | `Int?` | `nil` | New / Learning / Review / Relearning |
| `fsrsStability` | `Double?` | `nil` | |
| `fsrsDifficulty` | `Double?` | `nil` | |
| `fsrsLapses` | `Int` | `0` | |
| `schedulerVersion` | `String?` | `nil` | FSRS parameters used |
| `reviews` | `[ReviewLog]?` | `nil` | Optional inverse relationship |

`pronunciation` keeps holding the romanization, and `nextReviewAt` becomes the FSRS due date, so no field needs renaming. `easeFactor`, `interval` and `repetitions` stay but are no longer written.

### New `ReviewLog`

`id: UUID?`, `phrase: Phrase?`, `reviewedAt: Date`, `rating: Int` (hard / easy), `mode: String` (flashcard / audioRecall), `stateAfter: Int?`, `stabilityAfter: Double?`, `difficultyAfter: Double?`, `dueAfter: Date?`, `schedulerVersion: String?`. Insert only, never edited, so offline reviews on two devices never overwrite each other. The phrase's FSRS fields are a cache that can be rebuilt from the log.

### Settings stay on the device

All preferences stay in `@AppStorage`, as the app does today ([0009](decisions/0009-settings-stay-on-device.md)); nothing settings-related goes into SwiftData or CloudKit. Per-language settings (register: casual / neutral / polite; level override; daily new-card limit, default 10) are stored as one JSON-encoded value keyed by language code, behind `SettingsStore`, so moving them to a synced model later only changes that one implementation.

### Migration step

A pure, tested function run once at launch (tracked by a stored migration version):

1. Give every phrase without an `id` a new UUID; set `source = "legacy"` and `updatedAt = createdAt`.
2. Seed FSRS. There is no review history, so phrases with `repetitions > 0` start in Review with stability from `interval` and due = `nextReviewAt`; the rest start as New.
3. Map `formality` (`"formal"` → polite, else the language default) into each language's register in `SettingsStore`.
4. Leave phrases in dropped languages untouched; queries hide them. Show the one-time notice if any exist.
5. Missing level, gloss and reading are filled in later, on demand.

Risk: two devices may backfill different UUIDs for the same phrase before syncing. CloudKit keeps the last write, so nothing may rely on `id` until sync has settled. Relationships, not UUIDs, link reviews to phrases.

### Persistence modes

- **Local** (now): `ModelConfiguration(cloudKitDatabase: .none)`, and the entitlements file without iCloud or push, so a Personal Team can sign it.
- **CloudKit** (after renewal): `.private("iCloud.com.vladtamas.FlashSpeak")`.
- Chosen by a build flag. Because the local store uses the same schema, switching later only needs the CloudKit schema deployed, not a data migration.

**Before an App Store release** (see [current-state.md](current-state.md#what-makes-the-migration-tricky)): if 1.0 users can receive this build, map `targetText` and `pronunciation` to 1.0's `hanzi` and `pinyin` with `@Attribute(originalName:)`, and pick the starting language from the data present.

## Worker changes

### Layout

- Add `cloudflare-worker/wrangler.toml` (name, compatibility date, vars; the D1 binding comes later) and `package.json`, so `wrangler dev` works and the deployed configuration is recorded.
- Split `src/index.js` into `router.js`, `languages.js`, `prompts/` (one file per version), `anthropic.js`, `auth.js`, `usage.js`.
- `languages.js` holds the four languages (romanization spec, default register, level scale names) and must match `Language.allLanguages`.

### Endpoints

| Endpoint | Purpose |
| --- | --- |
| `POST /` | **Legacy, unchanged**, so any installed old build keeps working ([0008](decisions/0008-keep-legacy-worker-endpoint.md)) |
| `POST /v2/translate` | `{english, language, register?}` → translation |
| `POST /v2/suggest` | `{language, category, level, existing: [english], count: 5}` → suggestions |
| `POST /v2/flag` | Logs a bad-translation report |
| `GET /v2/config` | Languages, current prompt version, free limit |

v2 translate response:

```json
{
  "targetText": "...",
  "romanization": "...",
  "reading": "...",
  "gloss": [{"source": "...", "target": "..."}],
  "literal": "...",
  "alternative": "...",
  "usageNote": "...",
  "level": 2,
  "promptVersion": "2026-10.1",
  "usage": {"used": 1, "limit": 3, "remaining": 2}
}
```

`reading` is Japanese only; `romanization` is empty for Indonesian; `alternative` and `usageNote` are optional; `usage` is only sent once server-side limits exist.

### Prompts and model

- Prompts are versioned data on the server: per-language register rules from the PRD, the romanization spec, kana reading for Japanese, and the level scale. The version is returned with every result and stored on the phrase.
- Structured output through a tool or JSON schema, replacing "return raw JSON", so a fenced reply can no longer fail the request.
- Move from `claude-sonnet-4-20250514` to a current Sonnet, with `max_tokens` sized for the larger response.
- Later: `cloudflare-worker/evals/` runs the 50-phrase-per-language evaluation set against `wrangler dev` for every prompt change.

### Identity, limits and cost

**Now (app on one phone, no App Store):** no Worker authentication and no server-side usage counting ([0010](decisions/0010-no-worker-auth-until-app-store.md)). The `usage` field is omitted from v2 responses; the app keeps counting locally, and DEBUG builds are Pro anyway. The endpoint stays as open as it is today, so its URL must stay private; Anthropic spend can be capped in the Anthropic Console meanwhile.

**Before an App Store release:**

- **Storage:** D1 ([0007](decisions/0007-d1-for-worker-storage.md)) with tables for `usage` (user, local date, count), `flags` and `cost_log` (user, date, tokens, cost). D1 can increment a counter atomically; KV cannot.
- **Identity:** App Attest, and the StoreKit app transaction ID and signed transaction for identity and Pro status, as the PRD describes; a developer allow-list in Worker vars.
- The free limit is counted **on translate** (and once per suggestion batch), per user per local day, using the client's time zone sent with the request. `usage` is then returned in every v2 response.
- Every request logs Anthropic's `usage` tokens to `cost_log`.
- CORS is tightened to the methods and headers actually used.

The Worker is never deployed without asking (CLAUDE.md).

## Decisions

Taken on 2026-10-01 while agreeing this document:

| # | Decision | Record |
| --- | --- | --- |
| 1 | Worker storage is D1, added when server-side limits are built | [0007](decisions/0007-d1-for-worker-storage.md) |
| 2 | The legacy `POST /` endpoint stays unchanged alongside v2 | [0008](decisions/0008-keep-legacy-worker-endpoint.md) |
| 3 | Settings stay device-local in `@AppStorage`, as today | [0009](decisions/0009-settings-stay-on-device.md) |
| 4 | No Worker auth or server-side usage counting until the App Store release | [0010](decisions/0010-no-worker-auth-until-app-store.md) |
| 5 | Modules are folders in the one app target | [0011](decisions/0011-modules-as-folders.md) |

Still open, deferred until the membership is renewed: correcting CLAUDE.md's product IDs (`com.flashspeak.pro.*` vs `com.flashspeak.chinese.*`) and its wording about an "existing" CloudKit schema, once the [App Store facts](current-state.md#unknowns-to-check-before-an-app-store-release) are known.
