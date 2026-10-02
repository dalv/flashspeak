# FlashSpeak PRD

Sep 29, 2026 · @Vlad Tamas

## Overview

FlashSpeak turns the phrases a learner actually needs into spoken, reviewable cards: say it in English, hear how a local would say it, and practise it until it comes out without thinking.

The app already exists on the App Store as FlashSpeak, supporting Mandarin Chinese and Indonesian. This overhaul adds Korean and Japanese, keeps iCloud sync while preparing the data for a web app later, and adds suggested phrases, a way to clarify a translation in your own words, ready-made preset categories (numbers, days, connector words and more), and a hands-free audio recall mode.

**The problem.** Textbooks and translation tools give formal, literal phrasing that sounds stiff in real conversation. Learners also struggle to produce phrases quickly while speaking, because they have only ever read them, not heard and repeated them.

## Goals, non-goals and success metrics

**Goals**

- Capture a new phrase and hear a natural translation in under 5 seconds from the end of speaking.
- Translations a native speaker would call natural and casual, not textbook.
- Review that works with the screen off, in a pocket, with no taps.
- A data model that can move to a shared backend when the web app is built.
- A codebase that is easy to maintain with Claude Code: clear modules, swappable providers, tests.

**Non-goals for this release**

- The web app itself (the backend must be ready for it, the UI is later).
- Pronunciation scoring of the learner's own speech.
- Languages beyond the initial four.
- A lock screen widget displaying a few phrases of the current selected language every hour

**Success metrics**

| Metric | Target |
| --- | --- |
| Median time from end of speech to audio playback | under 5 s |
| Translations rated natural by a native reviewer (eval set) | 90% or more |
| Users who complete an audio recall session in week 1 | 40% or more |
| 30-day retention | to be baselined from the current app |
| Free to Pro conversion | to be baselined from the current app |

## Target user and product principles

The primary user is an English-speaking adult living in or travelling to a place where the target language is spoken, who wants to talk with locals rather than pass exams. They learn by building personal phrase sets for real situations (the "language islands" approach) and often learn two languages in parallel.

**Principles**

1. **Everyday register by default.** Speak like a friendly local: casual and natural, not formal and not heavy slang.
2. **Audio first.** Every phrase is heard before it is read; review works without looking at the screen.
3. **One tap to capture.** Adding a phrase must be faster than opening a notes app.
4. **Slow enough to follow.** Every playback can be slowed so a beginner hears each syllable.
5. **Both scripts, always.** Non-Latin languages show native script and romanization together.
6. **Calm and native.** Standard iOS patterns and Liquid Glass controls, no gamification noise.

## Platforms, backend and sync

Decision: keep iCloud for this release for a faster development cycle; a shared backend from day one was considered and deferred until the web app is built. Phrases sync across the user's Apple devices through their private iCloud database.

- **iPhone app:** SwiftUI, iOS 26 minimum, Liquid Glass. SwiftData on the device, synced through the existing CloudKit container, so the app works fully offline.
- **Per-language datasets:** every phrase has a language field; switching language switches the whole library.
- **AI proxy, not a full backend:** the existing Cloudflare Worker, extended, holds the LLM key (and later the voice key), checks App Attest and Pro status, counts free translations and logs cost. It stores no phrases.
- **No sign-in needed:** the proxy identifies a user by their StoreKit app transaction ID, so there is no account screen and the free limit survives reinstalls.
- **Sync rules:** CloudKit resolves conflicts per record; review history is append-only so offline reviews on two devices never overwrite each other; deletes are soft deletes, purged after 30 days.
- **Audio files** are not stored in this release (Apple voices speak on demand); with premium voices later they are stored as CloudKit assets with their phrase.
- **Ready for web later:** stable IDs on every record and a clean data layer, so the data can move to a shared backend (or be read on the web through CloudKit JS) without reshaping it.

&#91;embedded content: system architecture · app, backend, AI services\]

The app never holds AI or voice keys: phrases, reviews and audio sync through the user's own iCloud, and only translation and voice requests go through the small AI proxy. The web app is left out until the shared backend is built.

## Navigation and screen map

The app is one home screen with three actions and a menu; every other screen is one step away.

| Screen | Reached from | Purpose |
| --- | --- | --- |
| Home | App launch | Pick language, start one of the three actions |
| New phrase | Home | Speak, type or get suggested phrases, then save |
| Audio recall | Home | Hands-free listening practice |
| Flashcard recall | Home | Spaced-repetition review |
| Manage cards | Menu | Browse, play and delete phrases, by section (User phrases or a preset category) |
| Preset categories | Menu, Home empty state | Browse ready-made categories and add them to flashcards or audio recall |
| Settings | Menu | Language, playback, reminders, subscription |
| Paywall | New phrase (limit reached), Settings | Upgrade to Pro |
| Onboarding | First launch | Pick first language, grant microphone access |

## Main screen

The home screen shows the current language and three large actions; recording a new phrase is the most prominent.

- **Language selector** at the top: Mandarin Chinese, Indonesian, Korean, Japanese. The choice persists across launches and switches the whole phrase set.
- **New phrase:** the primary action, visually strongest.
- **Audio recall** and **Flashcard recall:** secondary actions. Each shows a small count (phrases in the set; cards due today).
- **Menu** (top right): Manage cards, Preset categories, Settings.
- **Empty state:** with no phrases yet, the recall actions are disabled with a one-line hint to add a phrase, try suggested phrases, or add a preset category such as Numbers.
- **Free users** see how many free translations remain today (for example "2 of 3 left").

## New phrase

The screen offers three ways in: speak (default), type, or get suggested phrases. All three end on the same result card.

**1. Speak (default)**

- A large microphone button, with a prompt such as "Say a phrase in English".
- Hold to talk, or tap to start and tap to stop. The live transcript shows while speaking.
- The user can edit the transcript before translating, or re-record.
- First use asks for microphone and speech permission, with a one-line explanation shown before the system prompt.

**2. Type**

- A text field with the keyboard open, and a Translate button. Used when speaking isn't possible.

**3. Suggest phrases**

1. The user picks a category.
2. The app generates 5 English phrases with translations, at the level of the user's set (see Duplicate detection and proficiency levels).
3. All 5 translations play in sequence immediately, at slow speed, each highlighted as it plays.
4. Each phrase can be replayed or unticked. A Save button at the bottom saves the ticked phrases; all are ticked by default.
5. "Suggest 5 more" generates a new batch in the same category.

Phrases can be short and useful rather than full sentences ("one more time", "turn left").

**Suggested categories**

| Group | Categories |
| --- | --- |
| Everyday | Greetings and small talk; Meeting someone at a party; Talking about yourself; Making plans with friends; Texting and chat replies |
| Out and about | At the grocery store; At a café or restaurant; At the market (bargaining); Getting and giving directions; Taking a taxi or ride-hail; Public transport |
| Services | At the pharmacy or doctor; At the bank or ATM; Phone and SIM card; At the hair salon; Dealing with a repair person |
| Places | At the gym; At the hotel or guesthouse; Renting an apartment; At the airport |
| Social | Compliments and thanks; Apologising and small problems; Asking for help; Agreeing and disagreeing; Classroom and "one more time, slowly please" |
| Emergencies | Lost items; Feeling unwell; Asking for the police or an ambulance |

Users can also type their own category (for example "at acro practice").

**Result card**

- English phrase, target-language phrase in native script, romanization (for Mandarin, Japanese, Korean), and a word-by-word gloss that can be expanded.
- Audio plays automatically if the auto-play setting is on, with a speed control (see Speech and audio spec) and a replay button.
- Actions: Save, Clarify (see below), Try another version (re-translate), Discard.
- If the phrase already exists in the set, the card says so and shows the existing card instead of saving a duplicate.

**Clarify a translation**

The translation isn't always the one the user had in mind. Clarify lets them say what's wrong in their own words, and the LLM adjusts the translation or offers different ones.

- **Input:** Clarify opens the same input as a new phrase: speak (default) or type, with the transcript editable before sending. The prompt gives examples: "it was something like *dai cha*…", "is there a more informal version, like *duo shao* something?", "I meant to a friend, not a waiter".
- **Sounded-out words:** transcription is English only, so a hint like "dai cha" may come out as "dye char". The transcript can be edited first, and the prompt tells the LLM that hints may be rough phonetic spellings of target-language words, possibly garbled by English speech recognition.
- **What is sent:** the original English, the translation shown, any earlier versions and clarifications for this phrase, the clarification, the language and the register.
- **What comes back:** one to three candidate translations, each a full result (native script, romanization, gloss, level, usage note), plus one line explaining what changed or what the user was probably thinking of ("You may mean 打车 dǎchē, 'take a taxi'"). If the clarification suggests the current translation is already right, the reply says so and keeps it.
- **Choosing:** with one candidate the result card updates in place and plays it. With several, they are shown as small cards with play buttons; picking one makes it the result card. "Back to previous version" restores the last one.
- **Repeat:** the user can clarify again on the new version. Free users get up to 3 clarifications per phrase; Pro is unlimited. Clarifications don't count toward the daily free translations.
- **Saving:** the duplicate check runs on the version that is saved. The phrase keeps its clarification text, so the user can see why the translation differs and flags include it.
- **After saving:** Clarify is also on the full card in Manage cards. Changing a saved phrase's translation keeps its review history and schedule.
- Clarify needs a connection; offline it is disabled with a short note.

## Phrase library: user phrases and preset categories

Each language's library has two parts: the user's own phrases, and ready-made preset categories of basic vocabulary that every learner needs.

**User phrases**

- Everything the user creates: spoken, typed, and suggested phrases they chose to save. Each keeps its source (spoken, typed, suggested).
- This is the default section in Manage cards and is always part of review.

**Preset categories**

- Curated lists of basic words and short phrases, the same for every user, in all four languages.
- **Opt in per category and per review mode.** The Preset categories screen lists them with a word count and a preview. Each category has two buttons, Flashcards and Audio recall, which add it to that set or remove it, after a confirmation that names the number of cards. Until added, a category can be browsed and played but is in neither set. Removing a category from flashcards resets its cards' progress; removing it from both deletes its cards, and adding it again starts fresh ([0022](decisions/0022-preset-review-sets.md)).
- **Content source:** written once per language with the translation prompt, checked by the same native reviewer as the evaluation set, and shipped inside the app as versioned data. Presets work offline, cost nothing per user, and don't count toward the free limit. Corrections ship with app updates and update the user's cards without losing review history.
- **Card format:** the front is the English (for numbers, the digits, with the English spoken); the back is native script, romanization and audio as for any phrase. Connector words and question words carry a short example phrase in the usage note, because a lone "because" is hard to recall without context.
- **Duplicates:** the duplicate check covers user phrases and started categories. If a new phrase matches a preset item, the result card shows the preset card.

| Category | Items |
| --- | --- |
| Numbers | 1–23, 34, 45, 56, 67, 78, 89, 95, 100, 115, 250, 275, 500, 750, 945, 1000, 2500, 5000 (40 cards) |
| Days of the week | Monday to Sunday, weekend |
| Connector words | and, or, but, if, because, so, when (as in "when I get home"), then, also, before, after |
| Question words | what, who, where, when, why, how, which, how much (price), how many |
| Time words | now, today, tomorrow, yesterday, later, soon, already, not yet, morning, afternoon, evening, tonight, this week, next week, last week, every day (no months) |

**Language notes for numbers (defaults, to confirm with the native reviewers)**

- **Mandarin:** 2 is 二 when counting and 两 before a measure word or in 两百 / 两千; the card shows the counting form and the usage note mentions 两. Larger numbers use the everyday spoken form (2500 两千五).
- **Japanese:** 4, 7 and 9 have two readings (yon/shi, nana/shichi, kyū/ku); the card uses the common one (yon, nana, kyū) and notes the other.
- **Korean:** Korean uses two number systems day to day, and the Korean Numbers category has both:
  - **Sino-Korean** (일, 이, 삼) for the 40 numbers above: prices, phone numbers, dates, minutes.
  - **Native Korean** (하나, 둘, 셋) for counting things, people, age and the hour: 1–20 and 30, 40, 50 (about 23 more cards), each with an everyday counter example in the usage note (한 개 one item, 두 명 two people, 세 시 three o'clock, 스무 살 twenty years old). The card front says which use it is ("3 · counting things").

## Translation quality spec

Translations come from an LLM called through the backend, with a prompt that asks for how a friendly local would actually say it, and a fixed test set that every prompt change must pass.

**Register per language (default)**

| Language | Default register | Avoid |
| --- | --- | --- |
| Indonesian | Everyday spoken Indonesian (bahasa sehari-hari): aku/kamu, natural particles like sih, dong, kok where they fit | Formal written Indonesian (saya/Anda everywhere) and heavy Jakarta slang (gue/lo) unless asked |
| Mandarin Chinese | Everyday Mainland spoken Mandarin, simplified characters | Written-style or literary phrasing |
| Japanese | Casual polite (desu/masu) for strangers; plain form available as an option | Keigo, textbook stiffness |
| Korean | Polite informal (-요 endings) | Formal -습니다 and banmal unless asked |

A register setting (casual / neutral / polite) can override the default per language.

**What the backend returns for each phrase**

- Translation in native script.
- Romanization: pinyin with tone marks; Hepburn romaji (plus kana reading for kanji); Revised Romanization for Korean. None for Indonesian.
- A literal word-by-word gloss.
- One alternative version when a common one exists (for example more casual).
- A short usage note when it matters ("used with friends only").
- An estimated level (see Duplicate detection and proficiency levels).

For a clarification (see New phrase) it returns one to three such results plus a one-line explanation.

**Quality process**

- The prompt, model and settings live on the server with a version number, so they can change without an App Store release.
- An evaluation set of 50 phrases per language with approved translations, reviewed by a native speaker (for example an iTalki tutor), plus about 10 clarification cases per language (a phrase, a first translation, a clarification and the expected result).
- A prompt change ships only if its outputs are at least as good as the current version on the evaluation set.
- The user can flag a bad translation from the result card; flags are logged for review.

## Speech and audio spec

For this overhaul all speech runs on the device with Apple's own frameworks: transcription for English and Apple's built-in voices for playback. A premium voice service comes in a later release.

**Speech to text (English)**

- Apple's on-device transcription (SpeechAnalyzer, iOS 26): free, private, works offline.
- The language model downloads on first use; show progress and let the user type meanwhile.

**Text to speech (target language)**

- **This release:** Apple's built-in voices (AVSpeechSynthesizer). Free, instant, offline, no keys and nothing to store.
- Voices: English is always spoken by one male voice; the target language is always spoken by one female voice per language. Keeping them fixed helps learners get used to each voice and tell the two languages apart by ear.
- Use Apple's Enhanced or Premium voice for each language when installed. If only the basic voice is present, offer a one-time tip explaining how to download the better voice in iOS Settings.
- **Later release:** a premium voice service (ElevenLabs, Azure or OpenAI, chosen per language after a blind listening test), called through the Cloudflare Worker, with audio generated once per phrase and cached.

**Playback speeds**

| Mode | How it plays | Used in |
| --- | --- | --- |
| Natural | Normal speed | Result card, flashcards (default) |
| Slow | About 0.6 to 0.75 of natural speed, pitch unchanged | Suggested phrases, audio recall (default) |
| Word by word | Each word on its own with a short pause, highlighted as it plays | On demand from any card |

- Speed is set through the speaking rate of Apple's voices, so switching is instant and pitch stays natural.
- Word-by-word mode uses the word positions Apple's speech engine reports while speaking, to highlight each word and pause between words.
- Tapping a word on any card plays that word alone.

**Caching**

- This release needs no audio caching: Apple's voices speak on demand on the device.
- With premium voices later, audio is generated once per phrase, saved with the phrase in iCloud and cached on the device, and regenerated only if the translation is edited.

## Duplicate detection and proficiency levels

No phrase is saved twice in a language set, and suggestions stay close to the level of what the user already has.

**Duplicates**

- **Exact duplicates** are blocked for every source (spoken, typed, suggested). Matching ignores case, punctuation and extra spaces, on both the English and the translation.
- **Near duplicates** ("where's the toilet" vs "where is the bathroom") are detected by meaning, using on-device sentence embeddings (Apple's Natural Language framework). The user sees the existing card and can save anyway or skip.
- **Suggestions** exclude anything close in meaning to an existing phrase. The app sends its existing phrases with the request and filters the results on the device, and generates replacements if fewer than 5 survive.

**Levels**

Each phrase gets a level when it is translated, on the scale the learner already knows for that language, mapped to one internal 1 to 6 scale.

| Internal level | Mandarin | Japanese | Korean | Indonesian |
| --- | --- | --- | --- | --- |
| 1 | HSK 1 | N5 | TOPIK 1 | A1 |
| 2 | HSK 2 | N4 | TOPIK 2 | A2 |
| 3 | HSK 3 | N3 | TOPIK 3 | B1 |
| 4 | HSK 4 | N2 | TOPIK 4 | B2 |
| 5 | HSK 5 | N1 | TOPIK 5 | C1 |
| 6 | HSK 6 | N1+ | TOPIK 6 | C2 |

- The set's current level is the median level of its most recent 50 phrases; a new set starts at 1.
- Suggestions are generated at the set's level, one below or one above.
- The user can see and override the set's level in Settings.
- Levels are shown on cards as a small label; they are estimates, not exam-accurate.

## Audio recall

Audio recall is a hands-free listening session: hear the English, try to say it yourself, then hear the answer. It runs with the screen off and the phone in a pocket.

**Each phrase plays like this**

1. The English phrase fades in and is spoken by the male English voice.
2. Three dots appear one by one over a 5-second thinking gap. The user tries to say the translation out loud.
3. The translation appears (native script and romanization) and is spoken by the female target-language voice at the session speed (slow by default).
4. It stays on screen for 1 second after the audio ends.
5. The next phrase starts.

**Session**

- Length options: 10, 20 or all phrases; default 20.
- Phrases come from User phrases and preset categories added to audio recall; the user can narrow a session to one section (for example only Numbers).
- Order: random, shuffled again for every session.
- Progress at the bottom: practised this session and total in the set ("12 of 20 · 148 in set").
- A summary at the end: phrases practised, time spent.

**Hands-free and background**

- Plays with the screen locked, like a podcast, and shows on the lock screen with play, pause and skip.
- Pauses on a phone call, Siri, or when headphones are disconnected, and resumes when the interruption ends.
- Mixes nothing else in: other audio (music) stops while a session plays.

**Screen on**

- Touch and hold anywhere pauses; releasing resumes. A small hint explains this on the first session.
- The pause works in the thinking gap and after the translation.
- Swipe to skip to the next phrase.

**Settings for this mode:** thinking gap (3, 5 or 8 seconds; default 5), playback speed, and an option to play the translation twice.

## Flashcard recall

Flashcards use the FSRS spaced-repetition algorithm, which needs fewer reviews than the classic Anki method for the same retention.

- **Front:** the English phrase. **Back:** native script, romanization, gloss; audio plays on flip if auto-play is on.
- Tap to flip; the user rates recall with two buttons, Hard or Easy (mapped to FSRS Again and Good), and FSRS sets the next review date. Two buttons is a deliberate choice: simpler than four.
- The session shows cards due today, plus up to 10 new cards per day (adjustable), from User phrases and preset categories added to flashcards. The user can narrow a session to one section.
- Progress at the top: cards left in this session.
- An optional reverse direction (target language on the front, listening only) for listening practice.
- Every review is stored as its own record so history syncs safely across devices and future FSRS versions can recalculate schedules.
- When nothing is due: "All caught up", with the next due time and a shortcut to audio recall.

## Manage cards

Manage cards lists every phrase in the current language, newest first, with search. A section picker at the top switches between User phrases and each started preset category.

- Each row: English, translation, romanization, level label; tap the play button to hear it.
- Tap a row to open the full card, where the translation can be edited (audio regenerates) or re-translated.
- Swipe left to delete, with Undo for a few seconds. In a preset category, swipe hides the item from review instead; it can be restored.
- **Delete all cards in this language:** a button at the bottom, confirmed by typing the language name, since it cannot be undone after 30 days.
- Sort options: newest, oldest, A to Z, level.

## Settings, subscription and entitlements

Free users get 3 translations per day; Pro removes the limit. The limit and Pro status are enforced by the AI proxy, not only in the app.

**Settings**

- Language (same selector as the home screen).
- Register per language: casual, neutral or polite.
- Auto-play audio on result cards and flashcard backs (default on).
- Default playback speed and audio recall options.
- Daily reminder: on or off, with a time (default 8 pm).
- Subscription: current plan, upgrade, restore purchases.
- Data: iCloud sync status, export my data, delete all my data.

**Free and Pro**

|  | Free | Pro |
| --- | --- | --- |
| Translations per day | 3 | Unlimited |
| Suggested phrase batches | Counts as 1 translation per batch | Unlimited |
| Clarifications | Up to 3 per phrase, not counted as translations | Unlimited |
| Preset categories | All, unlimited | All, unlimited |
| Audio recall and flashcards | Unlimited on saved phrases | Unlimited |
| Languages | All four | All four |

- The daily count resets at the user's local midnight and is counted on the server, so reinstalling does not reset it.
- When the limit is reached, the paywall opens; the typed or spoken phrase is kept so it translates right after upgrading.
- Purchases use StoreKit; the existing app's subscription products carry over. The app sends its signed StoreKit transaction with each request so the proxy can confirm Pro status.

**Developer access**

The developer's own account is Pro by default through an allow-list of the developer's app transaction ID in the AI proxy, not through code in the app. Debug builds can also switch between Free and Pro to test the paywall.

## Data model

Six records cover the product; phrases and reviews are the core, everything else supports them. Preset content itself ships inside the app; a preset item becomes a Phrase record only when its category is started, so it can be reviewed and synced like any other.

| Record | Key fields | Notes |
| --- | --- | --- |
| User | app transaction ID, entitlement (free / pro), developer override flag | Kept in the AI proxy, not iCloud; identifies the user without sign-in |
| Language settings | user, language, register, set level override, daily new-card limit, started preset categories | One per user per language |
| Phrase | id, user, language, English, translation, romanization, gloss, alternative, usage note, level, source (spoken / typed / suggested / imported / preset), preset category and item key, preset content version, clarifications, hidden from review, embedding, prompt version, created, updated, deleted at | The language field separates the sets; the source and preset category separate User phrases from presets |
| Audio | phrase, voice provider, voice id, audio file, word timings | Later release only (premium voices); not needed with Apple voices |
| Review | phrase, reviewed at, rating, mode (flashcard / audio recall), FSRS state after review | Append-only; drives scheduling |
| Usage | user, date, translations used | Kept in the AI proxy; enforces the free limit |

Phrases, audio and reviews live in the user's private iCloud database, which only they can access; the proxy keeps only usage counts and entitlement.

## Non-functional requirements

| Area | Requirement |
| --- | --- |
| Speed | Speech to playback under 5 s median; app launch to home screen under 1 s |
| Offline | Review modes, Manage cards and cached audio work with no connection; new translations queue until back online |
| Security | No AI or voice keys in the app; proxy calls require App Attest and a signed StoreKit transaction; per-user rate limits |
| Privacy | Speech is transcribed on the device; only the English text is sent to the AI proxy; a clear privacy policy and data export |
| Accessibility | Dynamic Type, VoiceOver labels on every control, captions for all audio, respects Reduce Motion |
| Design | Native iOS 26 components, Liquid Glass only for controls and navigation; one design-token file for colour, type and spacing |
| Typography | Fonts that render hanzi, kana, kanji and hangul well at large sizes; romanization shown under the native script |
| Cost | Audio generated once and cached; LLM and voice cost logged per user per day |
| Maintainability | Code split into modules (speech, translation, audio, review, design system, persistence); every external service behind an interface with a fake for tests and previews |
| Quality | Automated tests for the scheduler, duplicate detection and sync; the translation evaluation set runs on every prompt change |

## Migration from the current app

The new version ships as an update to the existing App Store app, so users, reviews, purchases and iCloud data all carry over.

- Keep the bundle ID, App Store record, in-app purchase products and CloudKit container.
- Extend the existing CloudKit schema rather than replacing it: production schema changes can only add record types and fields, never remove or rename them.
- On first launch after the update, existing Mandarin and Indonesian phrases keep their language, and new fields (level, gloss, romanization) are filled in where missing.
- Existing review history is converted into the new review records where possible; if not, cards start fresh in FSRS.
- Existing subscribers keep Pro automatically, confirmed through StoreKit.

* Minimum iOS rises from 18.1 to 26. People on older iOS keep the current version from the App Store.
* The app goes from about 20 languages to four. Phrases in other languages stay untouched in iCloud but are hidden, and users who have them see a one-time notice.

## Milestones and open questions

Build in five phases, testing the riskiest parts (voice quality and translation quality) before any UI polish.

1. **Prove the core.** Pick the best Apple voices per language (male English, female target) and check slow and word-by-word playback; first version of the translation prompt and its evaluation set, including clarification cases. Raise the minimum iOS version to 26.
2. **Foundations.** AI proxy (keys, App Attest, free limit), extended CloudKit schema, app skeleton with modules, design tokens, and the Claude Code setup (CLAUDE.md, build and test tools, skills).
3. **Capture.** Home, New phrase (speak, type, suggest), result card with Clarify, duplicate detection, levels, free limit and paywall.
4. **Review.** Flashcards with FSRS, audio recall with background playback, Manage cards, preset categories (content reviewed per language), Settings, reminders.
5. **Migrate and ship.** Schema upgrade for existing phrases, subscriber carry-over, TestFlight with a few learners per language, App Store update.

**Open questions**

- [ ] Pro price and whether to offer a yearly plan and a free trial.
- [ ] Does a suggested-phrase batch count as 1 translation or 5 for free users?
- [ ] Traditional characters and Taiwan Mandarin as an option later?
- [ ] When to move to premium voices, and which provider per language.
- [ ] Who reviews each language's evaluation set (a native tutor per language)?
- [ ] Should audio recall also accept the learner's spoken answer and check it (later release)?
- [x] Korean numbers: Numbers in Korean includes both systems as used day to day (see Language notes for numbers). Decided 2026-10-01.
- [x] Months: not part of any category. Decided 2026-10-01.
- [ ] More preset categories later (essential responses, pronouns and family, colours, directions)? Not now; revisit after release.

* [ ] Users with phrases in a dropped language: a notice only, or also an export option?

- [ ] When to move from iCloud to a shared backend (trigger: starting the web app).
