/// Something the system asks an audio recall session to do: lock screen
/// and headphone controls, and audio interruptions.
enum RecallSystemEvent: Equatable, Sendable {
    case play
    case pause
    case togglePlayPause
    case next
    /// A call, Siri or another app took the audio.
    case interruptionBegan
    case interruptionEnded(shouldResume: Bool)
    /// Headphones were unplugged or disconnected.
    case outputDisconnected
}

/// Lock screen info and controls for audio recall, plus interruption
/// events. Behind a protocol so sessions are testable.
@MainActor
protocol RecallSystemControls: AnyObject {
    /// Set by the session while it runs.
    var onEvent: ((RecallSystemEvent) -> Void)? { get set }
    func activate()
    func deactivate()
    func update(title: String, subtitle: String, isPlaying: Bool)
}

/// Records updates and lets tests send events.
@MainActor
final class FakeRecallSystemControls: RecallSystemControls {
    var onEvent: ((RecallSystemEvent) -> Void)?
    private(set) var isActive = false
    private(set) var lastUpdate: (title: String, subtitle: String, isPlaying: Bool)?

    nonisolated init() {}

    func activate() {
        isActive = true
    }

    func deactivate() {
        isActive = false
        onEvent = nil
    }

    func update(title: String, subtitle: String, isPlaying: Bool) {
        lastUpdate = (title, subtitle, isPlaying)
    }

    func send(_ event: RecallSystemEvent) {
        onEvent?(event)
    }
}
