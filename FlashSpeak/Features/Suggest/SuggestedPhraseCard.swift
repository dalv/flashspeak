import SwiftUI

/// One suggested phrase: include toggle, native text first, play. Outlined
/// in the accent while it is playing.
struct SuggestedPhraseCard: View {
    let item: SuggestModel.Item
    let languageCode: String
    let isPlaying: Bool
    @Binding var isIncluded: Bool
    let onPlay: () -> Void

    @Environment(\.languageTheme) private var theme

    var body: some View {
        PhraseRow(
            PhraseContent(
                english: item.english,
                native: item.translation.targetText,
                reading: item.translation.reading,
                romanization: item.translation.romanization,
                level: item.translation.level.map { LevelScale.label(for: $0, languageCode: languageCode) }
            ),
            style: .nativeFirst,
            isPlaying: isPlaying,
            isIncluded: $isIncluded,
            onPlay: onPlay
        )
        .padding(.vertical, DS.Spacing.s + 2)
        .padding(.leading, DS.Spacing.xxs)
        .padding(.trailing, DS.Spacing.rowPaddingHorizontal)
        .background(DS.Color.surface, in: .rect(cornerRadius: DS.Radius.list, style: .continuous))
        .overlay {
            if isPlaying {
                RoundedRectangle(cornerRadius: DS.Radius.list, style: .continuous)
                    .strokeBorder(theme.accent, lineWidth: DS.Size.selectedBorderWidth)
            }
        }
    }
}
