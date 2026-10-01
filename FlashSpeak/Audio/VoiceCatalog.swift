import AVFoundation

/// Chooses the voice for each role.
@MainActor
protocol VoiceCatalog: AnyObject {
    /// The best installed voice for a role, or nil to use the system default.
    func voice(for role: VoiceRole) -> AVSpeechSynthesisVoice?
    /// Whether an Enhanced or Premium voice is installed, for the one-time tip.
    func hasHighQualityVoice(for languageCode: String) -> Bool
}
