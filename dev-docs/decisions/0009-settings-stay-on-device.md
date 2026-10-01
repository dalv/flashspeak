# 0009. Settings stay on the device

- Status: Accepted
- Date: 2026-10-01

## Context

The PRD adds per-language settings (register, level override, daily new-card limit). They could sync through CloudKit as a SwiftData model or stay device-local like today's `@AppStorage` preferences.

## Decision

Keep all settings in `@AppStorage`, as the app does today. Per-language settings are stored as one JSON-encoded value keyed by language code, behind the `SettingsStore` protocol.

## Consequences

- No new CloudKit record type, and nothing to deduplicate.
- Settings don't follow the user to a second device.
- Moving them to a synced model later only changes the `SettingsStore` implementation.

Source: [architecture.md, Settings stay on the device](../architecture.md#settings-stay-on-the-device)
