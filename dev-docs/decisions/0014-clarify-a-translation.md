# 0014. Clarify a translation

- Status: Accepted
- Date: 2026-10-01

## Context

A learner often half-remembers what a local said ("something like *dai cha*") or wants a different register ("a more informal version"). Try another version re-translates blindly and can't use that hint.

## Decision

Add a Clarify action to the result card and to the full card in Manage cards. The user speaks or types a clarification, the Worker sends it to the LLM with the phrase's history, and gets back one to three candidate translations with a one-line explanation. Clarifications are free, up to 3 per phrase for free users, and unlimited for Pro.

## Consequences

- The Worker needs a clarify endpoint and the prompt needs clarification cases in its evaluation set.
- English-only transcription garbles sounded-out target words, so the transcript must be editable and the prompt must expect rough phonetic spellings.
- The proxy counts clarifications per phrase ID, separately from daily translations.
- Phrase gains a clarifications field (additive CloudKit change).

Source: [PRD, New phrase](../PRD.md#new-phrase)
