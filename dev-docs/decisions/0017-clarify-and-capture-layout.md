# 0017. Clarify placement and interim capture layout

- Status: Accepted (pending your review at Checkpoint A)
- Date: 2026-10-01

## Context

The mockups don't cover Clarify, and the Home tiles and menu lead to screens that Milestone 3 builds.

## Decision

- **Clarify** is a secondary glass button, "Not quite? Clarify", directly under the result card. It sits above the Discard / Retry / Save bar, so Save stays the one filled button.
- **The Clarify sheet** is large, so the speak input fits. It shows "Not what you meant?", three tappable examples (one sounded-out example per language), and the same Speak / Type input as New phrase with an editable transcript.
- **The Clarify reply** shows the explanation and candidate phrase cards with play and "Use this" (inline buttons, not filled).
- **After clarifying**, the result screen shows "You clarified: …" and a "Previous" button to step back through versions.
- **Retry** ("try another version") also keeps the earlier version reachable.
- **Toolbar buttons** (close, menu, flag) are in ink, not the accent, as in the mockups.
- **Bottom bars** use `safeAreaBar` for the native scroll-edge effect. The result bar moves Save onto its own row when the text size doesn't fit one row.
- **Until Milestone 3**, Audio recall, Flashcards, Manage cards, Preset categories and Settings open a "coming in the next milestone" placeholder. The legacy screens stay reachable with the DEBUG `-legacyUI` launch argument.
- **The Home New phrase card** uses the pale `accentTint` with ink text and a solid accent mic button, not the mockup's full accent fill, which read like an error (especially Mandarin red). Chosen on 2026-10-01 from solid, tinted and white versions.

## Consequences

- New phrase and Clarify share `SpeechInputModel`, `SpeakInputView` and `TypeInputView`.
- Placeholders are removed screen by screen in Milestone 3.

Source: [PRD, New phrase](../PRD.md#new-phrase)
