import SwiftUI

/// The back of a flashcard: the translation with audio, word by word and
/// the tappable gloss.
struct FlashcardBack: View {
    let content: PhraseContent
    let gloss: [GlossPair]
    let usageNote: String?
    let isPlaying: Bool
    let highlightedWord: Int?
    let onPlay: () -> Void
    let onWordByWord: () -> Void
    let onWord: (Int) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.m) {
                PhraseCard(
                    content,
                    showsEnglish: true,
                    alignment: .center,
                    isPlaying: isPlaying,
                    onPlay: onPlay,
                    controls: {
                        Button("Word by word", action: onWordByWord)
                            .buttonStyle(.inline)
                    }
                )
                .shadow(.card)

                if !gloss.isEmpty {
                    ResultWordGrid(gloss: gloss, highlighted: highlightedWord, onTap: onWord)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let usageNote, !usageNote.isEmpty {
                    Text(usageNote)
                        .appTextStyle(.secondary)
                        .foregroundStyle(DS.Color.inkSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    let language = SampleContent.languages[3]
    FlashcardBack(
        content: language.phrases[1],
        gloss: [],
        usageNote: "Polite and natural with staff.",
        isPlaying: false,
        highlightedWord: nil,
        onPlay: {},
        onWordByWord: {},
        onWord: { _ in }
    )
    .languageTheme(language.theme)
    .padding(DS.Spacing.screenPadding)
}
