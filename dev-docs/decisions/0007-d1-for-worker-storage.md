# 0007. D1 for Worker storage

- Status: Accepted
- Date: 2026-10-01

## Context

Before an App Store release, the Worker has to count free translations per user per day, log cost and store flagged translations ([0006](0006-extend-the-cloudflare-worker.md)). Cloudflare offers KV and D1. KV is eventually consistent and can't increment a counter atomically, so two quick requests could both pass the free limit.

## Decision

Use D1 (Cloudflare's SQLite) for the Worker's `usage`, `flags` and `cost_log` tables. Add it when server-side limits are built, not before ([0010](0010-no-worker-auth-until-app-store.md)).

## Consequences

- Usage counts are exact, and cost logs can be queried with SQL.
- The Worker needs a `wrangler.toml` D1 binding and a small migrations folder.
- Nothing changes until server-side limits are built.

Source: [architecture.md, Worker changes](../architecture.md#worker-changes)
