import SwiftUI

/// The gloss as a grid of word tiles; tapping one plays that word.
struct ResultWordGrid: View {
    let gloss: [GlossPair]
    let highlighted: Int?
    let onTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("Tap a word to hear it")
                .appTextStyle(.sectionLabel)
                .foregroundStyle(DS.Color.inkSecondary)
            FlowLayout(spacing: DS.Spacing.xs) {
                ForEach(Array(gloss.enumerated()), id: \.offset) { index, pair in
                    WordTile(
                        target: pair.target,
                        romanization: pair.romanization,
                        english: pair.english,
                        isHighlighted: highlighted == index
                    ) {
                        onTap(index)
                    }
                }
            }
        }
    }
}
