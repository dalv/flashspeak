# 0012. Bundle Noto Sans SC, JP and KR

- Status: Accepted
- Date: 2026-10-01

## Context

The PRD asks for fonts that render hanzi, kana, kanji and hangul well at large sizes. Native script is the largest text on most screens (34–42pt). Chinese and Japanese share Han code points but draw many characters differently, so each language needs a font for its own region. iOS has good system fonts (PingFang SC, Hiragino Sans, Apple SD Gothic Neo) at no size cost, but the mockups use Noto Sans SC / JP / KR.

## Decision

Bundle the region-subset OTFs of Noto Sans SC, JP and KR from notofonts/noto-cjk, Regular and Bold only, under the SIL Open Font License. Register them at launch with `CTFontManagerRegisterFontURLs` (no `UIAppFonts` entry). Indonesian uses SF Pro.

## Consequences

- The app grows by about 35 MB (SC 8.3 + 8.5 MB, JP 4.5 + 4.7 MB, KR 4.6 + 4.8 MB).
- One consistent look across the three CJK languages, matching the mockups.
- Only two weights; a semibold native style would need another file per script.
- Switching to system fonts later only changes `NativeScript.fontName(bold:)`; call sites use `.nativeTextStyle(_:script:)`.

Source: [design-system.md, Typography](../design-system.md#typography)
