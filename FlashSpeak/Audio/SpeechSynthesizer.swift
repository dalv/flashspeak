/// Speaks text in a role's voice.
@MainActor
protocol SpeechSynthesizer: AnyObject {
    var isSpeaking: Bool { get }
    /// Returns when speaking finishes or is stopped. `onWord` is called with
    /// the range of each word as it is spoken, for highlighting.
    func speak(
        _ text: String,
        role: VoiceRole,
        speed: PlaybackSpeed,
        onWord: ((Range<String.Index>) -> Void)?
    ) async
    func stop()
}

extension SpeechSynthesizer {
    func speak(_ text: String, role: VoiceRole, speed: PlaybackSpeed) async {
        await speak(text, role: role, speed: speed, onWord: nil)
    }
}
