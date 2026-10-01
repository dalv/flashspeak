import AVFoundation

/// What the audio session is set up for.
enum AudioMode: Sendable {
    /// Recording the user's English.
    case recording
    /// Playing a phrase in the foreground.
    case playback
    /// Audio recall: plays with the screen locked, stops other audio.
    case backgroundRecall
}

/// Owns the shared audio session so recording and playback don't fight.
@MainActor
protocol AudioSessionCoordinator: AnyObject {
    func activate(_ mode: AudioMode) throws
    func deactivate()
}

@MainActor
final class SystemAudioSessionCoordinator: AudioSessionCoordinator {
    private var current: AudioMode?

    func activate(_ mode: AudioMode) throws {
        guard mode != current else { return }
        let session = AVAudioSession.sharedInstance()
        switch mode {
        case .recording:
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP])
        case .playback:
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        case .backgroundRecall:
            try session.setCategory(.playback, mode: .spokenAudio)
        }
        try session.setActive(true)
        current = mode
    }

    func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        current = nil
    }
}

/// Does nothing; for Previews and tests.
@MainActor
final class FakeAudioSessionCoordinator: AudioSessionCoordinator {
    func activate(_: AudioMode) throws {}
    func deactivate() {}
}
