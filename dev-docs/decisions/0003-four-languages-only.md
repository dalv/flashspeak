# 0003. Four languages only

- Status: Accepted
- Date: 2026-09-29

## Context

The legacy app lists about 20 languages. The overhaul needs per-language work in each one: register rules, romanization, a proficiency scale, a translation evaluation set checked by a native speaker, and voice selection. Doing that well for 20 languages isn't feasible in this release.

## Decision

Support Mandarin Chinese, Indonesian, Korean and Japanese only. Remove the other languages from `Language.allLanguages` and from the Worker's `LANGUAGES` map.

## Consequences

- Phrases in dropped languages stay untouched in iCloud but are hidden. Users who have such phrases see a one-time notice.
- Still open: whether those users also get an export option.
- More languages are a non-goal for this release.

Source: [PRD, Migration from the current app](../PRD.md#migration-from-the-current-app)
