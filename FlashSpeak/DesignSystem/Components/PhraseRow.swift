import SwiftUI

/// One phrase in a list: English, native text, romanization, level and a
/// play button.
///
/// The row has no background of its own. Put it in a native `List` (so
/// swipe-to-delete stays native) or in a `surface` card. Pass `isIncluded`
/// to show a leading check toggle, as on the suggested-phrases screen.
struct PhraseRow: View {
    private let phrase: PhraseContent
    private let style: PhraseRowStyle
    private let isPlaying: Bool
    private let isIncluded: Binding<Bool>?
    private let onPlay: (() -> Void)?

    @Environment(\.languageTheme) private var theme

    init(
        _ phrase: PhraseContent,
        style: PhraseRowStyle = .englishFirst,
        isPlaying: Bool = false,
        isIncluded: Binding<Bool>? = nil,
        onPlay: (() -> Void)? = nil
    ) {
        self.phrase = phrase
        self.style = style
        self.isPlaying = isPlaying
        self.isIncluded = isIncluded
        self.onPlay = onPlay
    }

    var body: some View {
        HStack(spacing: DS.Spacing.s) {
            if let isIncluded {
                Toggle("Include", isOn: isIncluded)
                    .toggleStyle(.checkCircle)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xxs / 2) {
                switch style {
                case .englishFirst:
                    Text(phrase.english)
                        .appTextStyle(.subheadlineEmphasized)
                        .foregroundStyle(DS.Color.ink)
                    PhraseRowNativeLine(phrase: phrase, script: theme.script)
                case .nativeFirst:
                    Text(phrase.native)
                        .nativeTextStyle(.row, script: theme.script)
                        .foregroundStyle(isExcluded ? DS.Color.inkSecondary : DS.Color.ink)
                    if let romanization = phrase.romanization {
                        Text(romanization)
                            .appTextStyle(.footnote)
                            .foregroundStyle(DS.Color.inkSecondary)
                    }
                    Text(phrase.english)
                        .appTextStyle(.secondary)
                        .foregroundStyle(isExcluded ? DS.Color.inkSecondary : DS.Color.ink)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            if style == .englishFirst {
                if let level = phrase.level {
                    LevelLabel(level, size: .compact)
                }
            }

            if let onPlay {
                PlayButton(size: style == .englishFirst ? .compact : .row, isPlaying: isPlaying, action: onPlay)
            }
        }
    }

    private var isExcluded: Bool {
        isIncluded?.wrappedValue == false
    }
}

/// Native text followed by its romanization, flowing as one wrapped line.
private struct PhraseRowNativeLine: View {
    let phrase: PhraseContent
    let script: NativeScript

    var body: some View {
        if let romanization = phrase.romanization, let nativeFont = NativeTextStyle.inline.customFont(for: script) {
            let native = Text(phrase.native).font(nativeFont).foregroundStyle(DS.Color.ink)
            Text("\(native)  \(romanization)")
                .appTextStyle(.secondary)
                .foregroundStyle(DS.Color.inkSecondary)
                .typesettingLanguage(script.language)
        } else {
            Text(phrase.native)
                .nativeTextStyle(.inline, script: script)
                .foregroundStyle(DS.Color.ink)
        }
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    @Previewable @State var included = [true, true, false]

    List {
        ForEach(SampleContent.languages) { language in
            Section(language.theme.displayName) {
                ForEach(language.phrases.prefix(2)) { phrase in
                    PhraseRow(phrase) {}
                }
                PhraseRow(language.phrases[2], style: .nativeFirst, isPlaying: true, isIncluded: $included[0]) {}
                PhraseRow(language.phrases[3], style: .nativeFirst, isIncluded: $included[2]) {}
            }
            .dsListRows()
            .languageTheme(language.theme)
        }
    }
    .dsGroupedList()
}
