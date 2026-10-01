# 0011. Modules as folders in one target

- Status: Accepted
- Date: 2026-10-01

## Context

The PRD asks for code split into modules (speech, translation, audio, review, design system, persistence). They could be folders in the app target or local Swift packages.

## Decision

Make each module a folder under `FlashSpeak/` in the single app target. Features depend on protocols, and only the `App` composition root creates concrete types.

## Consequences

- No package setup. The file-system-synchronized group picks up new files without `project.pbxproj` edits.
- The compiler doesn't enforce module boundaries; the dependency rule in architecture.md does.
- Any module can be lifted into a local Swift package later.

Source: [architecture.md, Modules](../architecture.md#modules)
