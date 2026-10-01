import SwiftUI

/// The live transcript: confirmed words in ink, words that may still change
/// in the tertiary ink (decorative; the whole line is read by VoiceOver).
struct TranscriptText: View {
    let transcript: Transcript
    let placeholder: String

    var body: some View {
        Group {
            if transcript.text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(DS.Color.inkSecondary)
            } else if transcript.finalized.isEmpty {
                Text(transcript.volatile)
                    .foregroundStyle(DS.Color.inkTertiary)
            } else {
                Text("\(Text(transcript.finalized).foregroundStyle(DS.Color.ink)) \(Text(transcript.volatile).foregroundStyle(DS.Color.inkTertiary))")
            }
        }
        .appTextStyle(.transcript)
        .multilineTextAlignment(.center)
        .accessibilityLabel(transcript.text.isEmpty ? placeholder : transcript.text)
    }
}
