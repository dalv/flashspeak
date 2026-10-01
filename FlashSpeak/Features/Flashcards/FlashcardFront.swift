import SwiftUI

/// The front of a flashcard: the English, or in reverse mode a play
/// button only (listening practice). Tapping anywhere flips it.
struct FlashcardFront: View {
    let english: String
    let isReversed: Bool
    let isPlaying: Bool
    let onPlay: () -> Void
    let onFlip: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.l) {
            Text(isReversed ? "Listen" : "English")
                .appTextStyle(.eyebrow)
                .foregroundStyle(DS.Color.inkSecondary)

            if isReversed {
                PlayButton(size: .large, isPlaying: isPlaying, action: onPlay)
            } else {
                Text(english)
                    .appTextStyle(.display)
                    .foregroundStyle(DS.Color.ink)
                    .multilineTextAlignment(.center)
            }

            Text(isReversed ? "Say what it means, then tap to flip" : "Say it, then tap to flip")
                .appTextStyle(.secondary)
                .foregroundStyle(DS.Color.inkSecondary)
        }
        .padding(DS.Spacing.flashcardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.surface, in: .rect(cornerRadius: DS.Radius.cardLarge))
        .shadow(.card)
        .contentShape(.rect(cornerRadius: DS.Radius.cardLarge))
        .onTapGesture(perform: onFlip)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Show answer", onFlip)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack(spacing: DS.Spacing.l) {
        FlashcardFront(english: "Could I get the check, please?", isReversed: false, isPlaying: false, onPlay: {}, onFlip: {})
        FlashcardFront(english: "An iced Americano, please", isReversed: true, isPlaying: true, onPlay: {}, onFlip: {})
            .languageTheme(.korean)
    }
    .padding(DS.Spacing.screenPadding)
}
