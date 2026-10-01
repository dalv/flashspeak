import Observation

/// A `SpeechSynthesizer` for Previews and tests. Records what it was asked
/// to say and finishes immediately.
@MainActor
@Observable
final class FakeSpeechSynthesizer: SpeechSynthesizer {
    private(set) var isSpeaking = false
    private(set) var spoken: [(text: String, role: VoiceRole, speed: PlaybackSpeed)] = []

    func speak(
        _ text: String,
        role: VoiceRole,
        speed: PlaybackSpeed,
        onWord: ((Range<String.Index>) -> Void)?
    ) async {
        spoken.append((text, role, speed))
        onWord?(text.startIndex ..< text.endIndex)
    }

    func stop() {
        isSpeaking = false
    }
}
