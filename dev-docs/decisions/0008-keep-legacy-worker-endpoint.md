# 0008. Keep the legacy Worker endpoint

- Status: Accepted
- Date: 2026-10-01

## Context

The new app needs a richer translation response. We don't yet know which Worker version is deployed, or whether an installed build still depends on today's `POST /` contract (see [current-state.md](../current-state.md#unknowns-to-check-before-an-app-store-release)).

## Decision

Leave `POST /` exactly as it behaves today, and add the new API under `/v2/` (`translate`, `suggest`, `flag`, `config`).

## Consequences

- Deploying the new Worker can't break an installed old build.
- A little legacy code stays in the Worker. It can be removed once no supported build calls it.

Source: [architecture.md, Endpoints](../architecture.md#endpoints)
