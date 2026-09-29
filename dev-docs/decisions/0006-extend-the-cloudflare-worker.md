# 0006. Extend the Cloudflare Worker

- Status: Accepted
- Date: 2026-09-29

## Context

The app needs server-side help for AI calls, the free-translation limit and Pro checks, but it doesn't need a full backend, because phrases sync through iCloud (see [0001](0001-keep-icloud-for-now.md)). The existing Cloudflare Worker already proxies translation requests to Claude.

## Decision

Extend the existing Worker into a small AI proxy instead of building a backend. The Worker:

- holds the LLM key, and later the voice key
- checks App Attest and Pro status from the signed StoreKit transaction
- counts free translations per user and logs cost
- identifies users by their StoreKit app transaction ID, so no sign-in is needed
- keeps the prompt, model and settings versioned on the server
- stores no phrases.

## Consequences

- The app never holds a key, and prompt changes ship without an App Store release.
- The free limit survives reinstalls, because it is counted on the server.
- The Worker needs storage for usage counts and entitlements.
- The developer's Pro access comes from an allow-list in the Worker, not from code in the app.

Source: [PRD, Platforms, backend and sync](../PRD.md#platforms-backend-and-sync)
