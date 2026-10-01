import SwiftUI

/// One candidate translation from a clarification: listen, then use it.
struct ClarifyCandidateCard: View {
    let english: String
    let candidate: TranslationResult
    let languageCode: String
    let onPlay: () -> Void
    let onUse: () -> Void

    var body: some View {
        PhraseCard(
            PhraseContent(
                english: english,
                native: candidate.targetText,
                reading: candidate.reading,
                romanization: candidate.romanization,
                level: candidate.level.map { LevelScale.label(for: $0, languageCode: languageCode) }
            ),
            onPlay: onPlay,
            controls: {
                Button("Use this", action: onUse)
                    .buttonStyle(.inline)
            },
            footer: {
                if let note = candidate.usageNote {
                    Text(note)
                        .appTextStyle(.secondary)
                        .foregroundStyle(DS.Color.inkSecondary)
                }
            }
        )
    }
}
