# 0019. Audio recall is practice only

- Status: Accepted
- Date: 2026-10-01

## Context

Audio recall has no rating buttons, so the app can't tell whether the learner recalled the phrase.

## Decision

Audio recall never writes a `ReviewLog` and never changes a card's schedule. It uses the schedule only to order the session (due cards first). Only flashcard ratings move FSRS.

## Consequences

- Listening practice can't push a card later than the learner deserves.
- `ReviewMode.audioRecall` stays in the schema, unused, in case a later release checks spoken answers (open PRD question).
