# 0001. Keep iCloud for now

- Status: Accepted
- Date: 2026-09-29

## Context

A web app is planned, and it will eventually need a shared backend. Building that backend now would slow down the overhaul, and the current app already syncs through CloudKit.

## Decision

Keep SwiftData synced through the existing CloudKit container (`iCloud.com.vladtamas.FlashSpeak`) for this release. Defer a shared backend until the web app is started.

## Consequences

- Development is faster, the app works fully offline, and existing users' data carries over.
- Production schema changes can only add record types and fields, never rename or remove them.
- Records get stable IDs and a clean data layer, so the data can move to a shared backend later without reshaping it.
- Reviews are append-only and deletes are soft deletes, so two devices syncing offline don't overwrite each other.

Source: [PRD, Platforms, backend and sync](../PRD.md#platforms-backend-and-sync)
