import SwiftUI

/// Speak input: explains, asks permission, downloads the model if needed,
/// listens with a live transcript, then lets the user edit before sending.
/// Shared by New phrase ("Translate") and Clarify ("Send").
struct SpeakInputView: View {
    @Bindable var speech: SpeechInputModel
    let prompt: String
    let primaryTitle: String
    let isWorking: Bool
    let onPrimary: () -> Void
    let onTypeInstead: () -> Void

    @Environment(\.languageTheme) private var theme
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
            controls
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        switch speech.state {
        case .idle, .requestingPermission:
            VStack(spacing: DS.Spacing.s) {
                Text(prompt)
                    .appTextStyle(.transcript)
                    .foregroundStyle(DS.Color.ink)
                    .multilineTextAlignment(.center)
                Text("Speech is turned into text on your iPhone. Nothing is recorded.")
                    .appTextStyle(.secondary)
                    .foregroundStyle(DS.Color.inkSecondary)
                    .multilineTextAlignment(.center)
            }
        case let .preparing(progress):
            VStack(spacing: DS.Spacing.m) {
                ProgressView(value: progress)
                    .tint(theme.accent)
                Text("Downloading English speech recognition. You can type meanwhile.")
                    .appTextStyle(.secondary)
                    .foregroundStyle(DS.Color.inkSecondary)
                    .multilineTextAlignment(.center)
                Button("Type instead", action: onTypeInstead)
                    .buttonStyle(.secondary)
            }
        case .listening:
            VStack(spacing: DS.Spacing.xl) {
                Label("Listening", systemImage: "circle.fill")
                    .labelStyle(ListeningLabelStyle())
                    .foregroundStyle(theme.accentText)
                TranscriptText(transcript: speech.transcript, placeholder: "Go ahead…")
                ListeningWaveform(isActive: true)
            }
        case .finished:
            TextField("Your phrase in English", text: $speech.text, axis: .vertical)
                .appTextStyle(.transcript)
                .foregroundStyle(DS.Color.ink)
                .multilineTextAlignment(.center)
                .lineLimit(1 ... 5)
                .submitLabel(.done)
                .accessibilityHint("Edit before sending")
        case .permissionDenied:
            VStack(spacing: DS.Spacing.m) {
                Text("FlashSpeak needs the microphone and speech recognition to hear you.")
                    .appTextStyle(.body)
                    .foregroundStyle(DS.Color.ink)
                    .multilineTextAlignment(.center)
                HStack(spacing: DS.Spacing.s) {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    .buttonStyle(.secondary)
                    Button("Type instead", action: onTypeInstead)
                        .buttonStyle(.secondary)
                }
            }
        case let .failed(message):
            VStack(spacing: DS.Spacing.m) {
                Text(message)
                    .appTextStyle(.body)
                    .foregroundStyle(DS.Color.ink)
                    .multilineTextAlignment(.center)
                Button("Type instead", action: onTypeInstead)
                    .buttonStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        if speech.state == .finished {
            HStack(spacing: DS.Spacing.s) {
                Button("Again", systemImage: "arrow.counterclockwise") {
                    speech.reset()
                }
                .buttonStyle(.secondary)
                .accessibilityLabel("Record again")
                PrimaryButton(LocalizedStringKey(primaryTitle), isLoading: isWorking, action: onPrimary)
                    .disabled(speech.text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } else {
            VStack(spacing: DS.Spacing.s) {
                RecordButton(
                    isRecording: speech.isListening,
                    onPressChanged: speech.pressChanged,
                    onAccessibilityActivate: speech.toggle
                )
                .disabled(speech.isBusy || speech.state == .permissionDenied)
                Text(speech.isListening ? "Tap to stop · or hold to talk" : "Tap to start · or hold to talk")
                    .appTextStyle(.secondary)
                    .foregroundStyle(DS.Color.inkSecondary)
            }
        }
    }
}

/// A small dot before "Listening".
private struct ListeningLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            configuration.icon
                .imageScale(.small)
                .font(.system(size: DS.Spacing.xs))
            configuration.title
                .appTextStyle(.subheadlineEmphasized)
        }
    }
}
