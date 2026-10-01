# 0010. No Worker auth until the App Store release

- Status: Accepted
- Date: 2026-10-01

## Context

The developer licence has expired, so for now the app runs only on the developer's phone, signed with a free Personal Team. App Attest and real StoreKit transactions, which the PRD uses for identity and Pro status, need a paid membership and an App Store build.

## Decision

Until the App Store release, the Worker has no authentication and no server-side usage counting. The app keeps counting free translations locally, and v2 responses leave out the `usage` field.

## Consequences

- The fastest route to a working app on the phone.
- The endpoint is as open as it is today: its URL must stay private, and Anthropic spend should be capped in the Anthropic Console.
- App Attest, StoreKit identity, D1 usage counting ([0007](0007-d1-for-worker-storage.md)) and a developer allow-list must be built before an App Store release.

Source: [architecture.md, Identity, limits and cost](../architecture.md#identity-limits-and-cost)
