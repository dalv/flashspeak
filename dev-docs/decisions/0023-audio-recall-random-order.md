# 0023. Audio recall plays in a random order

- Status: Accepted
- Date: 2026-10-02

## Context

The PRD ordered an audio recall session by due cards first, then phrases added in the last week (newest first), then the rest at random. In use, the session played the same order every time. A freshly added preset category is entirely "recent", so it always played in reverse catalog order.

## Decision

Every session shuffles all eligible phrases, then cuts the list to the session length (10, 20 or all). Due dates and creation dates no longer affect the order.

## Consequences

- Each session sounds different, and a 10- or 20-card session draws a different sample each time.
- A short session may skip cards that are due for flashcard review. That's acceptable because audio recall is practice only and never schedules ([0019](0019-audio-recall-is-practice-only.md)).

Source: Vlad's request, 2026-10-02.
