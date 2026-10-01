# 0015. Preset categories, opt in, shipped with the app

- Status: Accepted
- Date: 2026-10-01

## Context

Learners need basic vocabulary (numbers, days, connector words) that they rarely think to say as a phrase. The library should separate these from the user's own phrases.

## Decision

Each language's library has User phrases (spoken, typed and saved suggestions) and preset categories: Numbers, Days of the week, Connector words, Question words and Time words. Preset content is written once per language, checked by a native reviewer, and shipped inside the app as versioned data. A category enters review only when the user starts it; its items then become Phrase records with source `preset`.

## Consequences

- Presets work offline, cost nothing per user, and are free for everyone.
- Starting a category can't flood the daily queue unexpectedly; the new-card limit still applies.
- Content corrections need an app update and must update existing cards without losing review history, so each item has a stable key and a content version.
- Review and Manage cards need a section filter.

Source: [PRD, Phrase library](../PRD.md#phrase-library-user-phrases-and-preset-categories)
