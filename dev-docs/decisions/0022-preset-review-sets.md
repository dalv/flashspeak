# 0022. Presets join flashcards and audio recall separately

- Status: Accepted (amends 0015)
- Date: 2026-10-02

## Context

0015 gave each preset category one switch: "Start learning" put it into both flashcards and audio recall, and Pause hid it from both while keeping its history. In use, Vlad wants a category such as Numbers in audio recall without it filling the flashcard queue, or the other way round.

## Decision

- Each category has two buttons, Flashcards and Audio recall, side by side with short labels. Each one adds the category to that set or removes it, after a confirmation that gives the card count.
- Presets are in neither set until added. Phrase gains two additive fields, `excludedFromFlashcards` and `excludedFromRecall`, both defaulting to false so user phrases and existing records stay in both sets. Preset cards are created with both set to true, and only the set being added is switched on.
- Removing a category from flashcards resets its cards to new. Removing it from both soft-deletes its cards, so adding it again creates fresh ones. Vlad accepted the reset in exchange for a simpler model.
- Pause/Resume is gone. Categories paused under the old design are deleted once, at launch.
- `hiddenFromReview` keeps its meaning: the per-card Hide in Manage cards, which hides a card from both sets.
- Flashcards and audio recall only offer the categories in their own set when narrowing a session to one section.

## Consequences

- Removing from flashcards loses review history for those cards, so the confirmation says so.
- Old builds don't know the new fields, so they'd show recall-only presets in flashcards. That only matters across mixed app versions on one iCloud account, and none are released yet.

Source: Vlad's request, 2026-10-02.
