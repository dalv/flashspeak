# 0013. Dark mode from this release

- Status: Accepted (palette values pending review in the component gallery)
- Date: 2026-10-01

## Context

The mockups define light mode only, plus an always-dark audio recall screen. The app could force light mode or support dark mode now.

## Decision

Support dark mode. Neutrals switch to a dark palette built from the recall colours (`ground` = `#0E1014`, `ink` = `#F3F4F6`, `inkSecondary` = `#9AA1AD`) with a `#1A1D23` surface. Accent fills stay the same in both modes. Accent tints become the accent at 24% over `surface`. A new `accentText` role uses `accentOnDark` for accent-coloured text in dark mode, and a new `dangerFill` keeps white text readable on destructive fills. Audio recall is unchanged.

## Consequences

- Every text pair passes WCAG AA in both modes (checked against the token values), except the decorative `inkTertiary`.
- Views must use `accentText`, not `accent`, for accent-coloured text and icons on `ground` or `surface`.
- The dark values are proposals, not designed mockups; adjust them in `Tokens.swift` and `LanguageTheme.swift` only.

Source: [design-system.md, Colour](../design-system.md#colour)
