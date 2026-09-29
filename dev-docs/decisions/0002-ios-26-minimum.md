# 0002. iOS 26 minimum

- Status: Accepted
- Date: 2026-09-29

## Context

The current app targets iOS 18.1. The overhaul relies on SpeechAnalyzer for on-device transcription and on Liquid Glass for the design, and both need iOS 26.

## Decision

Raise the deployment target from iOS 18.1 to iOS 26. Use iOS 26 APIs freely, with no availability checks for older versions.

## Consequences

- Less code to write and test, because there are no fallbacks.
- People on older iOS keep the current version from the App Store.

Source: [PRD, Migration from the current app](../PRD.md#migration-from-the-current-app)
