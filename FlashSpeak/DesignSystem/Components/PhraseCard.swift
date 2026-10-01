import SwiftUI

/// A phrase on a solid card: labels, native text, reading, romanization
/// and a play button.
///
/// Used for the translation result (`.leading`, hero size) and the
/// flashcard back (`.center`, flashcard size, with the English on top).
/// `controls` sits next to the play button (e.g. the speed control);
/// `footer` goes below (e.g. word tiles). Content, so never glass.
struct PhraseCard<Controls: View, Footer: View>: View {
    private let phrase: PhraseContent
    private let register: String?
    private let showsEnglish: Bool
    private let alignment: HorizontalAlignment
    private let isPlaying: Bool
    private let onPlay: () -> Void
    private let controls: Controls
    private let footer: Footer

    @Environment(\.languageTheme) private var theme

    init(
        _ phrase: PhraseContent,
        register: String? = nil,
        showsEnglish: Bool = false,
        alignment: HorizontalAlignment = .leading,
        isPlaying: Bool = false,
        onPlay: @escaping () -> Void,
        @ViewBuilder controls: () -> Controls = { EmptyView() },
        @ViewBuilder footer: () -> Footer = { EmptyView() }
    ) {
        self.phrase = phrase
        self.register = register
        self.showsEnglish = showsEnglish
        self.alignment = alignment
        self.isPlaying = isPlaying
        self.onPlay = onPlay
        self.controls = controls()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: alignment, spacing: DS.Spacing.m) {
            if showsEnglish {
                Text(phrase.english)
                    .appTextStyle(.body)
                    .foregroundStyle(DS.Color.inkSecondary)
            }

            if !isCentered {
                PhraseCardLabels(level: phrase.level, register: register)
            }

            VStack(alignment: alignment, spacing: DS.Spacing.xs) {
                Text(phrase.native)
                    .nativeTextStyle(isCentered ? .flashcard : .hero, script: theme.script)
                    .foregroundStyle(DS.Color.ink)
                if let reading = phrase.reading {
                    Text(reading)
                        .nativeTextStyle(.reading, script: theme.script)
                        .foregroundStyle(DS.Color.inkSecondary)
                }
                if let romanization = phrase.romanization {
                    Text(romanization)
                        .appTextStyle(.romanization)
                        .foregroundStyle(isCentered ? DS.Color.ink : DS.Color.inkSecondary)
                }
            }
            .multilineTextAlignment(isCentered ? .center : .leading)
            .accessibilityElement(children: .combine)

            if isCentered {
                PhraseCardLabels(level: phrase.level, register: register)
            }

            HStack(spacing: DS.Spacing.s) {
                PlayButton(size: isCentered ? .large : .medium, isPlaying: isPlaying, action: onPlay)
                controls
            }

            footer
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
        .padding(isCentered ? DS.Spacing.flashcardPadding : DS.Spacing.cardPadding)
        .background(
            DS.Color.surface,
            in: .rect(cornerRadius: isCentered ? DS.Radius.cardLarge : DS.Radius.card)
        )
    }

    private var isCentered: Bool {
        alignment == .center
    }
}

/// Level and register labels.
private struct PhraseCardLabels: View {
    let level: String?
    let register: String?

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            if let level {
                LevelLabel(level)
            }
            if let register {
                LevelLabel(register, style: .neutral)
            }
        }
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    @Previewable @State var speed = "Slow"

    ScrollView {
        VStack(spacing: DS.Spacing.l) {
            ForEach(SampleContent.languages) { language in
                Group {
                    PhraseCard(language.phrases[0], register: "Casual", onPlay: {}, controls: {
                        SegmentedControl(selection: $speed, options: ["Natural", "Slow", "Word by word"], variant: .inline) {
                            Text($0)
                        }
                    })
                    PhraseCard(language.phrases[1], showsEnglish: true, alignment: .center, onPlay: {}, controls: {
                        Button("Word by word") {}
                            .buttonStyle(.inline)
                    })
                    .shadow(.card)
                }
                .languageTheme(language.theme)
            }
        }
        .padding(DS.Spacing.screenPadding)
    }
}
