# 0020. Export is CSV

- Status: Accepted
- Date: 2026-10-01

## Decision

"Export my phrases" in Settings shares one CSV file of every phrase in the four languages: language, English, translation, romanization, reading, level, section and date added. RFC 4180 quoting, UTF-8 with a byte order mark so Numbers and Excel show hanzi, kana and hangul correctly. Built only when the user shares it.

## Consequences

- Opens in Numbers, Excel and Google Sheets, and imports into Anki.
- Schedules, glosses and clarifications aren't exported; a JSON backup can be added later if needed.
