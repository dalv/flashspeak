# 0021. Phase 4 details the PRD leaves open

- Status: Proposed (please review)
- Date: 2026-10-01

## Context

Building Flashcards, Audio recall, Manage cards, Preset categories and Settings needed some small choices the PRD doesn't spell out. Each is easy to change.

## Decisions

- **Hard brings a card back in the same session** when FSRS schedules it within 15 minutes (new and lapsed cards), as Anki does.
- **The daily new-card limit counts cards already introduced today**, so reopening Flashcards doesn't hand out another 10.
- **Audio recall order:** due cards (most overdue first), then phrases added in the last 7 days (newest first), then the rest shuffled. "Then the newest" is read as "added this week".
- **Audio recall has its own speed setting** (default Slow), separate from the default speed (Natural) used on cards.
- **Audio recall starts from a setup screen** (session length and section), then runs; a summary ends it.
- **Pausing:** touch-down pauses and release resumes; a lock-screen or interruption pause shows "Paused · tap to resume". A call resumes playback when it ends; unplugging headphones doesn't.
- **Editing a saved phrase** (re-translate or Clarify on the full card) saves each new version straight away; "Previous" undoes it. Hand edits clear the word-by-word gloss, which would no longer match.
- **Deleting** is a soft delete with 5 seconds of Undo; deleted phrases are purged 30 days later at launch.
- **"Delete all my data"** soft-deletes every phrase in every language and turns the reminder off. Settings and the subscription stay.
- **The reminder** shows a random phrase from the current language ("How do you say …?") and is rescheduled with a new one each time Home opens. Tapping it opens Flashcards.
- **Pausing a preset category** hides all its cards; resuming un-hides all of them, including ones hidden one by one.
- **The DEBUG "act as a free user" switch** in Settings replaces the `-forceFree` launch argument for everyday testing (the argument still works).

Source: [PRD, Audio recall, Flashcard recall, Manage cards, Settings](../PRD.md)
