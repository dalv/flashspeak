import Foundation
import Observation

/// Listening state for a speak input: permission, model download, live
/// transcript, then an editable result. Used by New phrase and Clarify.
@MainActor
@Observable
final class SpeechInputModel {
    enum State: Equatable {
        case idle
        case requestingPermission
        case preparing(progress: Double)
        case listening
        /// Stopped; `text` holds the editable transcript.
        case finished
        case permissionDenied
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var transcript: Transcript = .empty
    /// The transcript after listening stops, editable before sending.
    var text = ""

    var isListening: Bool {
        state == .listening
    }

    var isBusy: Bool {
        switch state {
        case .requestingPermission, .preparing: true
        default: false
        }
    }

    /// Holding longer than this and releasing stops (hold to talk).
    static let holdThreshold: Duration = .milliseconds(350)

    @ObservationIgnored private let service: any TranscriptionService
    @ObservationIgnored private var streamTask: Task<Void, Never>?
    @ObservationIgnored private var pressStart: ContinuousClock.Instant?
    @ObservationIgnored private var wasListeningAtPress = false

    init(service: any TranscriptionService) {
        self.service = service
    }

    // MARK: - Gestures

    /// Touch down or release on the record button. A tap toggles; a hold
    /// records while held.
    func pressChanged(_ pressing: Bool) {
        if pressing {
            pressStart = .now
            wasListeningAtPress = isListening
            if !isListening {
                Task { await start() }
            }
        } else {
            let held = pressStart.map { ContinuousClock.now - $0 } ?? .zero
            pressStart = nil
            if wasListeningAtPress || held >= Self.holdThreshold {
                Task { await stop() }
            }
        }
    }

    func toggle() {
        Task { isListening ? await stop() : await start() }
    }

    // MARK: - Listening

    func start() async {
        guard !isListening, !isBusy else { return }
        state = .requestingPermission
        guard await service.requestPermission() else {
            state = .permissionDenied
            return
        }
        do {
            state = .preparing(progress: 0)
            try await service.prepare { [weak self] progress in
                if case .preparing = self?.state {
                    self?.state = .preparing(progress: progress)
                }
            }
            let stream = try await service.start()
            transcript = .empty
            text = ""
            state = .listening
            streamTask = Task { [weak self] in
                do {
                    for try await update in stream {
                        self?.transcript = update
                    }
                } catch {
                    self?.state = .failed("Listening stopped. Try again, or type it instead.")
                }
            }
        } catch {
            state = .failed("Speech recognition isn't available right now. You can type instead.")
        }
    }

    func stop() async {
        guard isListening else { return }
        await service.stop()
        await streamTask?.value
        streamTask = nil
        text = transcript.text
        state = .finished
    }

    /// Back to idle, discarding the transcript.
    func reset() {
        Task { await service.stop() }
        streamTask?.cancel()
        streamTask = nil
        transcript = .empty
        text = ""
        state = .idle
    }
}
