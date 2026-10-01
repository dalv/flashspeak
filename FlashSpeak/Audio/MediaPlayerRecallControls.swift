import AVFoundation
import MediaPlayer

/// `RecallSystemControls` on MediaPlayer's now-playing info and remote
/// commands, with AVAudioSession interruption and route-change
/// notifications.
@MainActor
final class MediaPlayerRecallControls: RecallSystemControls {
    var onEvent: ((RecallSystemEvent) -> Void)?

    private var commandTargets: [(MPRemoteCommand, Any)] = []
    private var observers: [NSObjectProtocol] = []

    func activate() {
        guard commandTargets.isEmpty else { return }
        let center = MPRemoteCommandCenter.shared()
        register(center.playCommand, .play)
        register(center.pauseCommand, .pause)
        register(center.togglePlayPauseCommand, .togglePlayPause)
        register(center.nextTrackCommand, .next)

        let notifications = NotificationCenter.default
        observers.append(notifications.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] note in
            let event = Self.interruptionEvent(note)
            MainActor.assumeIsolated {
                if let event { self?.onEvent?(event) }
            }
        })
        observers.append(notifications.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] note in
            let disconnected = Self.isOutputDisconnected(note)
            MainActor.assumeIsolated {
                if disconnected { self?.onEvent?(.outputDisconnected) }
            }
        })
    }

    func deactivate() {
        for (command, target) in commandTargets {
            command.removeTarget(target)
        }
        commandTargets.removeAll()
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        onEvent = nil
    }

    func update(title: String, subtitle: String, isPlaying: Bool) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: subtitle,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }

    private func register(_ command: MPRemoteCommand, _ event: RecallSystemEvent) {
        command.isEnabled = true
        let target = command.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.onEvent?(event) }
            return .success
        }
        commandTargets.append((command, target))
    }

    private nonisolated static func interruptionEvent(_ note: Notification) -> RecallSystemEvent? {
        guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return nil }
        switch type {
        case .began:
            return .interruptionBegan
        case .ended:
            let options = (note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt)
                .map(AVAudioSession.InterruptionOptions.init(rawValue:)) ?? []
            return .interruptionEnded(shouldResume: options.contains(.shouldResume))
        @unknown default:
            return nil
        }
    }

    private nonisolated static func isOutputDisconnected(_ note: Notification) -> Bool {
        guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt else { return false }
        return AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable
    }
}
