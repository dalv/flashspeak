# Design system

Status: **Built, awaiting review** (2026-10-01). Derived from the mockups in [design/mockups/](design/mockups/) (`DesignTokens.dc.html` plus the 12 screen mockups). Dark-mode values are proposed here; the mockups are light only. Decisions: [0012](decisions/0012-bundle-noto-cjk-fonts.md) (fonts), [0013](decisions/0013-dark-mode-palette.md) (dark mode).

Requirements from the [PRD](PRD.md#non-functional-requirements):

- Native iOS 26 components. Liquid Glass only on controls and navigation, never on content cards.
- One design-token file for colour, type and spacing. No hardcoded values in views.
- Fonts that render hanzi, kana, kanji and hangul well at large sizes, with romanization shown under the native script.
- Dynamic Type, VoiceOver labels on every control, and support for Reduce Motion.

## Principles

- **Calm, warm, focused.** A light grey ground, solid white content, one accent colour per language.
- **Glass is for controls, not content.** Nav buttons, segmented controls and floating actions use native Liquid Glass. Phrase cards, lists and flashcards are solid surface.
- **One filled accent button per screen.** It is the thing to do next (Save, Continue, Easy, Suggest 5 phrases).
- **The phrase is the hero.** Native script is the largest text on any screen it appears on; romanization sits directly under it in secondary colour.
- **Audio recall is always dark**, with huge type and nothing else on screen.

The mockups imitate glass with CSS (`rgba(255,255,255,0.6)` + blur + border + shadow). That styling is **not** a token; in the app it is replaced by SwiftUI's `glassEffect` and the `.glass` / `.glassProminent` button styles.

## Where it lives

`FlashSpeak/DesignSystem/` (a folder module, see [0011](decisions/0011-modules-as-folders.md)). It depends on nothing else in the app.

| Path | Contents |
| --- | --- |
| `Tokens.swift` | `DS.Color`, `DS.Spacing`, `DS.Radius`, `DS.Size`, `DS.Shadow`: the one token file |
| `LanguageTheme.swift`, `LanguageTheme+Environment.swift` | Per-language accents, `\.languageTheme`, `.languageTheme(_:)` |
| `Typography/` | `AppTextStyle`, `NativeTextStyle`, `NativeScript`, their modifiers, `FontRegistration` |
| `Fonts/` | Noto Sans SC / JP / KR Regular and Bold (OTF) and the OFL licence |
| `Components/` | One file per component |
| `Preview/` | `DesignSystemPreview` (preview trait that registers fonts) and `SampleContent` in all four languages |
| `Gallery/` | `ComponentGallery` and its sections |

**Component gallery.** Open `Gallery/ComponentGallery.swift` in Xcode for the Light, Dark and Accessibility-text previews. In a DEBUG build, launch with `-componentGallery` to show it instead of the app; `-gallerySection buttons` scrolls to a section and `-galleryLanguage ko` picks a language.

**Usage.**

```swift
Text(phrase.english).appTextStyle(.headline).foregroundStyle(DS.Color.ink)
Text(phrase.native).nativeTextStyle(.hero, script: theme.script)
Button("Save", action: save).buttonStyle(.primary)
SomeScreen().languageTheme(.forCode(language.code) ?? .mandarin)
```

## Colour

### Neutrals (main app)

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `ground` | `#F2F3F5` | `#0E1014` | Screen background; inline segmented-control and inline-button track; neutral label background |
| `surface` | `#FFFFFF` | `#1A1D23` | Cards, lists, fields, chips, selected segment thumb |
| `surfaceSunken` | `#F7F8FA` | `#22262D` | Word tiles inside a card |
| `ink` | `#15171C` | `#F3F4F6` | Primary text and icons |
| `inkSecondary` | `#5B616E` | `#9AA1AD` | Secondary text, section labels, romanization, unselected segments |
| `inkTertiary` | `#9AA0AB` | `#6B717C` | Unconfirmed live-transcript words (decorative; below 4.5:1, never for information on its own) |
| `onAccent` | `#FFFFFF` | `#FFFFFF` | Text and icons on an accent or `dangerFill` fill |
| `hairline` | `#E3E5EA` | `#2C3038` | Field and chip borders, progress track, divider inside cards |
| `separator` | `#EDEFF2` | `#252930` | Row separators inside lists |
| `controlBorder` | `#D5D8DE` | `#3A3F48` | Outlined secondary button (Hard) |
| `controlBorderStrong` | `#B8BDC7` | `#555B66` | Unchecked check circles and radio rings |
| `danger` | `#B42318` | `#F97066` | Destructive text and icons |
| `dangerFill` | `#B42318` | `#D92D20` | Fill behind white text (swipe to delete); `danger` is too light for that in dark mode |

The mockups also use `#C9CDD4` for the sheet grabber; the app uses the system grabber, so it is not a token.

### Recall (always dark)

| Token | Hex | Use |
| --- | --- | --- |
| `recallGround` | `#0E1014` | Audio recall background |
| `recallInk` | `#F3F4F6` | English prompt, counts |
| `recallInkSecondary` | `#9AA1AD` | Labels, hints, English on the answer screen |
| `recallTrack` | white at 12% | Progress track, unfilled thinking dots (18%) |

### Language accents

Each language has one theme with four roles. Components read it from the environment (`\.languageTheme`), and the app also sets `.tint(theme.accent)` so native controls (toggles, links) follow it.

| Language | `accent` | `accentTint` (light / dark) | `accentOnTint` (light / dark) | `accentOnDark` |
| --- | --- | --- | --- | --- |
| Mandarin | `#C23B22` | `#FBEAE6` / `#422423` | `#A8321D` / `#F08A73` | `#F08A73` |
| Indonesian | `#0B7A6F` | `#E3F2F0` / `#163335` | `#0A6A61` * / `#6FD3C6` | `#6FD3C6` |
| Korean | `#2B55C7` | `#E7EDFA` / `#1E2A4A` | `#254AAD` * / `#8FA9F0` | `#8FA9F0` |
| Japanese | `#9B2F6B` | `#F5E6EE` / `#392134` | `#8A2960` / `#E08AB8` | `#E08AB8` |

A fifth role, `accentText`, is the accent used as text or an icon on `ground` or `surface` (the "12" in "12 due today", Restore purchases, tinted play icons). It is `accent` in light mode and `accentOnDark` in dark mode, because the accents are only 2.7–3.7:1 on the dark ground. `accent` itself doesn't change in dark mode: white on it still passes.

- `accent`: filled buttons, play button, the mic button on the New phrase card, selected language segment, progress fill, toggles, selected chip border and text. Large areas are never filled with the accent: a full-accent card read as an error state (2026-10-01, Home).
- `accentTint`: the Home New phrase card, icon wells on Home tiles, small play buttons in rows, level-label background, selected chip and active word tile background.
- `accentOnTint`: text on `accentTint` (level labels). The mockups only define Mandarin and Japanese; the two marked * are derived the same way (about 87% of `accent`). Dark tints are the accent at 24% over `surface`.
- `accentOnDark`: the target-language text, progress and thinking dots in audio recall.

Contrast (WCAG), checked against the values in `Tokens.swift` and `LanguageTheme.swift` in both modes: every text pair passes AA (4.5:1) except the decorative `inkTertiary`. White on `accent` 5.2–7.0:1; white on `dangerFill` 6.6 / 4.8:1; `accentOnTint` on `accentTint` 5.6–7.6:1; `accentText` on `ground` and `surface` ≥ 4.8:1; `accentOnDark` on `recallGround` 7.7–10.7:1.

## Typography

**UI and English: SF Pro** (the system font). **Native script: Noto Sans SC (Mandarin), Noto Sans JP (Japanese), Noto Sans KR (Korean)**, Regular and Bold, bundled with the app. Indonesian is Latin script and uses SF Pro at the native sizes. Using a separate font per language matters for Han characters: the same code point is drawn differently in Chinese and Japanese, so Japanese text must never fall back to the SC font or vice versa.

Every style is a fixed design size that **scales with Dynamic Type** relative to a system text style: `Font.custom(_:size:relativeTo:)` for Noto, and a `@ScaledMetric(relativeTo:)` size for SF. Apply them with `.appTextStyle(_:)` and `.nativeTextStyle(_:script:)`; the native modifier also sets `typesettingLanguage` for line breaking. The fonts are registered at launch by `FontRegistration` (no Info.plist entry). Noto's own line height (about 1.45) already spaces stacked CJK lines, so no extra line spacing is applied.

### UI styles (SF Pro)

| Style | Size / weight | Relative to | Used for |
| --- | --- | --- | --- |
| `largeTitle` | 34 bold | `.largeTitle` | Home "FlashSpeak", Manage cards heading, Paywall title (mockup 32, normalised) |
| `title` | 28 bold | `.title` | Settings, "Pick a situation" |
| `display` | 30 bold | `.title` | Home hero "New phrase", flashcard English prompt |
| `transcript` | 30 semibold | `.title` | Live transcript while listening |
| `recallPrompt` | 36 bold | `.largeTitle` | English prompt in audio recall |
| `tileTitle` | 18 bold | `.headline` | Home tile titles |
| `headline` | 17 bold | `.headline` | Nav titles, primary button, Hard / Easy |
| `body` | 17 regular | `.body` | English phrase under a title, Paywall intro |
| `callout` | 16 regular / semibold | `.callout` | Settings rows, secondary buttons, fields |
| `subheadline` | 15 regular / bold | `.subheadline` | List-row English (bold), segment labels, chips |
| `secondary` | 14 regular / bold (`secondaryEmphasized`) | `.subheadline` | Tile subtitles, hints, inline segments (speed, register) |
| `sectionLabel` | 13 bold (colour `inkSecondary` set by the caller) | `.footnote` | Section headings, level labels |
| `eyebrow` | 13 bold, uppercase, 1pt tracking | `.footnote` | "ENGLISH" above a prompt |
| `footnote` | 13 regular | `.footnote` | Nav subtitles, plan prices, counts |
| `caption` | 12 regular / bold (`captionEmphasized`) | `.caption` | Level label in list rows (bold), word-tile romanization and gloss |
| `romanization` | 19 regular, `inkSecondary` | `.title3` | Romanization under the hero phrase |

### Native-script styles (Noto Sans SC / JP / KR, or SF for Indonesian)

| Style | Size / weight | Relative to | Used for |
| --- | --- | --- | --- |
| `nativeRecall` | 42 bold | `.largeTitle` | Answer in audio recall |
| `nativeFlashcard` | 38 bold | `.largeTitle` | Flashcard back |
| `nativeHero` | 34 bold | `.largeTitle` | Result card; Manage cards heading (中文) |
| `nativeTile` | 20 bold | `.title3` | Word tiles |
| `nativeRow` | 18 bold | `.headline` | Suggested-phrase rows |
| `nativeSegment` | 15 bold | `.subheadline` | Language picker labels |
| `nativeInline` | 14 regular | `.subheadline` | Native text inside list rows and hints |
| `nativeReading` | 15 regular | `.subheadline` | Kana reading line under Japanese (Noto Sans JP) |

Native text at 34pt and above gets line height ≈ 1.25–1.3 (extra line spacing) so stacked CJK lines don't touch. Headings at 28pt and above use slight negative tracking (−0.3 to −0.5) as in the mockups.

## Spacing

Steps: `xxs 4 · xs 8 · s 12 · m 16 · l 20 · xl 24 · xxl 32`.

| Token | Value | Use |
| --- | --- | --- |
| `screenPadding` | 20 | Horizontal screen margin (recall: 24) |
| `cardPadding` | 20 | Result card, Home tiles (flashcard: 28 = `xl` + `xxs`) |
| `rowPaddingH` / `rowPaddingV` | 14 / 12 | List rows |
| `stackGap` | 16–20 | Between blocks on a screen |

Odd values in the mockups (6, 10, 14) are normalised to the nearest step except `rowPaddingH` 14, which matches the iOS inset-list inset.

## Shape

| Token | Radius | Use |
| --- | --- | --- |
| `cardLarge` | 32 | Flashcard |
| `card` | 28 | Result card, Home hero |
| `tile` | 24 | Home tiles |
| `list` | 20 | Lists, suggested-phrase cards, Paywall plan options (mockup 18–20) |
| `field` | 14 | Search and text fields |
| `small` | 12 | Word tiles, level labels |
| capsule | — | Buttons, chips, segmented controls, play buttons |

All rounded rectangles use continuous corners (`RoundedRectangle(cornerRadius:style: .continuous)`).

## Sizes

| Token | Value |
| --- | --- |
| `minTouch` | 44 (glass icon buttons, nav, check circles) |
| `compactButtonHeight` | 36 (Upgrade in a settings row) |
| `primaryButtonHeight` | 54 (mockups use 52–56) |
| `ratingButtonHeight` | 64 (Hard / Easy, two lines) |
| `segmentHeight` / `inlineSegmentHeight` | 40 (glass), 36 (inline) |
| `playButton` | 56 large, 52 medium, 40 row, 36 compact |
| `recordButton` | 88, with a 124 halo at `accent` 14% |
| `progressBarHeight` | 4 |

## Elevation

Content on `ground` is flat by default. Two exceptions from the mockups:

- `shadowCard`: black 6%, radius 30, y 10. Flashcard only.
- `shadowAccent`: `accent` 28–35%, radius 30, y 10. The mic button on the Home New phrase card and the record button.

Glass controls bring their own depth; no shadow token is applied to them.

## Liquid Glass (native)

| Mockup element | SwiftUI |
| --- | --- |
| Round nav buttons (back, close, menu, flag) | Toolbar items in a `NavigationStack` get glass automatically. Outside a toolbar: `GlassIconButton` (`glassEffect(.regular.interactive(), in: .circle)`, 44pt) |
| Capsule text button (Newest first, Discard, Retry, 5 more, Show answer) | `.buttonStyle(.secondary)`: `glassEffect(.regular.interactive(), in: .capsule)` |
| Top-level segmented controls (language, Speak / Type / Suggest) | `SegmentedControl` with `.glassAccent` or `.glass`: a glass capsule track, the selected thumb moving with `matchedGeometryEffect` |
| Recall top-bar buttons on dark | Same components; glass adapts to the dark ground |

Controls **inside a card** are not glass: `SegmentedControl` with `.inline` (playback speed, register) and `.buttonStyle(.inline)` ("Word by word") use a solid `ground` capsule.

Glass respects Reduce Transparency automatically. Thumb animations and the playing waveform are still under Reduce Motion. Segmented controls cap Dynamic Type at xxLarge, like the system control, and show the large content viewer on long press.

## Components

| Component | Mockups | Notes |
| --- | --- | --- |
| `GlassIconButton` | All screens | SF Symbol, required title (read by VoiceOver), optional `accentText` foreground (Pause on Suggested phrases) |
| `SegmentedControl` | Home, Listening, Result, Settings | Generic over a `Hashable` option with a label builder, so language labels render in their own script. Variants: `.glassAccent` (language picker), `.glass` (input mode), `.inline` (inside cards) |
| `PrimaryButton` / `.buttonStyle(.primary)` | Result, Paywall, Suggest | Full-width solid `accent` capsule, white `headline`, 54pt. One per screen. `PrimaryButton` adds a loading state. `.primaryCompact` for Upgrade in a row |
| `.buttonStyle(.secondary)` | Result, Flashcard, Suggested | Glass capsule, `ink` `callout` semibold, optional leading symbol |
| `.buttonStyle(.inline)` | Flashcard back | Solid `ground` capsule for a button inside a card |
| `RatingButtons` | Flashcard back | Hard (surface, `controlBorder` outline) and Easy (`accent` fill), each with a sub-label ("Again soon", "In 4 days") |
| `PhraseCard` | Result, Flashcard back | Solid `surface` card. `.leading` (result: labels on top, hero size) or `.center` (flashcard: English on top, flashcard size, labels below). `controls` slot next to the play button, `footer` slot below (word tiles later) |
| `PhraseRow` | Manage cards, Suggested | `.englishFirst` (Manage: English bold, native + romanization flowing as one line, level label, compact play) or `.nativeFirst` (Suggested: native, romanization, English, row play). Optional `isIncluded` binding shows a check-circle toggle. No background: sits in a native `List` so swipe-to-delete stays native |
| `SettingsRow` | Settings | Title, optional subtitle, trailing value or view. Wrap in `NavigationLink` for a chevron or use as a native `Toggle` label. Lists use `.dsGroupedList()` and `.dsListRows()` |
| `PhraseContent` | — | Plain values the phrase components take (English, native, reading, romanization, level), so the design system doesn't depend on the `Phrase` model |
| `LevelLabel` | Result, Flashcard, Manage | Capsule, `accentTint` background, `accentOnTint` text ("HSK 2", "JLPT N4", "TOPIK 1", "A2"); neutral variant for register ("Casual") |
| `PlayButton` | Several | Circle; filled `accent` (large, medium) or `accentTint` with `accentText` icon (row, compact). Playing state swaps to an animated waveform symbol |
| `CheckCircleToggleStyle` | Suggested | `.toggleStyle(.checkCircle)` for including a suggestion |

Later, built with the screens that need them: Home tile, word tile, chip, check circle, progress bar, listening waveform, record button, recall thinking dots.

## Mockup inconsistencies resolved here

- Recall progress and thinking dots use `#4FC3B5`, while the Indonesian answer uses `#6FD3C6` (`accentOnDark`). The app uses `accentOnDark` for all three, so there is one dark accent per language.
- Paywall title is 32; normalised to `largeTitle` 34.
- List radius 18 (Settings, Paywall) and 20 (Manage, Suggested) → both `list` 20.
- Primary button heights 52, 54, 56 → one height, 54.

## Resolved questions (2026-10-01)

1. **Dark mode:** supported from this release; values above ([0013](decisions/0013-dark-mode-palette.md)). Proposed, not from the mockups, so review them in the gallery's Dark preview.
2. **Fonts:** Noto Sans SC / JP / KR Regular and Bold are bundled, about 35 MB ([0012](decisions/0012-bundle-noto-cjk-fonts.md)).
3. **Primary button:** solid `accent` fill, as in the mockups.
