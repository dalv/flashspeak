import SwiftUI

/// The translation in audio recall: native script, reading and
/// romanization, with "Speaking slowly" while it plays.
struct RecallAnswer: View {
    let phrase: Phrase
    let isSpeaking: Bool
    let speed: PlaybackSpeed

    @Environment(\.languageTheme) private var theme

    var body: some View {
        VStack(spacing: DS.Spacing.xxl) {
            VStack(spacing: DS.Spacing.xs) {
                Text(phrase.targetText)
                    .nativeTextStyle(.recall, script: theme.script)
                    .foregroundStyle(theme.accentOnDark)
                if let reading = phrase.reading {
                    Text(reading)
                        .nativeTextStyle(.reading, script: theme.script)
                        .foregroundStyle(DS.Color.recallInkSecondary)
                }
                if !phrase.pronunciation.isEmpty {
                    Text(phrase.pronunciation)
                        .appTextStyle(.romanization)
                        .foregroundStyle(DS.Color.recallInk)
                }
            }
            Label(speed == .natural ? "Speaking" : "Speaking slowly", systemImage: "speaker.wave.2")
                .appTextStyle(.secondary)
                .foregroundStyle(DS.Color.recallInkSecondary)
                .opacity(isSpeaking ? 1 : 0)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    VStack(spacing: DS.Spacing.xxl) {
        ForEach(Language.supportedCodes, id: \.self) { code in
            if let phrase = try? dependencies.phrases.phrases(in: code, section: .all, sort: .newest).first {
                RecallAnswer(phrase: phrase, isSpeaking: code == "id", speed: .slow)
                    .languageTheme(LanguageTheme.forCode(code) ?? .mandarin)
            }
        }
    }
    .frame(maxWidth: .infinity)
    .background(DS.Color.recallGround)
}
