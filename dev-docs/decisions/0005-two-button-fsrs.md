# 0005. Two-button FSRS

- Status: Accepted
- Date: 2026-09-29

## Context

The legacy app uses a simplified SM-2 scheduler with two buttons, Hard and Easy. FSRS needs fewer reviews than SM-2 for the same retention. FSRS normally uses four ratings, but two buttons is a deliberate product choice.

## Decision

Replace SM-2 with FSRS and keep two buttons: Hard maps to FSRS Again and Easy maps to FSRS Good.

## Consequences

- Each review is stored as its own append-only record, so history syncs safely and future FSRS versions can recalculate schedules.
- Legacy review history is converted where possible; otherwise, cards start fresh in FSRS.
- The legacy one-character-per-tap hanzi reveal is dropped.
- The scheduler is pure logic, covered by the Phase 2 test target.

Source: [PRD, Flashcard recall](../PRD.md#flashcard-recall)
