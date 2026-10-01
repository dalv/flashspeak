import Foundation
import Observation

/// A hands-free audio recall session (PRD, Audio recall). For each phrase:
/// the English in the male voice, a thinking gap with three dots, the
/// translation in the female voice at the session speed (optionally
/// twice), then a one-second hold.
///
/// Practice only: it never writes reviews or changes a schedule
/// (decision 0019).
@MainActor
@Observable
final class RecallSession {
    enum Phase: Equatable {
        case english
        case thinking(dots: Int)
        case answer
        case hold
        case finished
    }

    /// Waits; tests pass one that returns at once.
    typealias Sleep = @MainActor (Duration) async throws -> Void

    let phrases: [Phrase]
    let setCount: Int
    private(set) var index = 0
    private(set) var phase: Phase = .english
    private(set) var isPaused = false
    private(set) var practisedCount = 0
    private(set) var startedAt: Date?
    private(set) var finishedAt: Date?

    @ObservationIgnored private let dependencies: AppDependencies
    @ObservationIgnored private let sleep: Sleep
    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private var step: Step = .english
    @ObservationIgnored private var run: Task<Void, Never>?
    @ObservationIgnored private var pausedBySystem = false
    @ObservationIgnored private var activeSeconds: TimeInterval = 0
    @ObservationIgnored private var resumedAt: Date?

    private enum Step {
        case english, thinking, answer, hold
    }

    static let holdAfterAnswer: Duration = .seconds(1)
    static let pauseBetweenRepeats: Duration = .milliseconds(700)

    init(
        phrases: [Phrase],
        setCount: Int,
        dependencies: AppDependencies,
        sleep: @escaping Sleep = { try await Task.sleep(for: $0) },
        clock: @escaping () -> Date = { .now }
    ) {
        self.phrases = phrases
        self.setCount = setCount
        self.dependencies = dependencies
        self.sleep = sleep
        self.clock = clock
        if phrases.isEmpty { phase = .finished }
    }

    var speed: PlaybackSpeed {
        dependencies.settings.recallSpeed
    }

    var current: Phrase? {
        phrases.indices.contains(index) ? phrases[index] : nil
    }

    var isFinished: Bool {
        phase == .finished
    }

    /// "12 of 20": the phrase being played, counting from 1.
    var position: Int {
        min(index + 1, phrases.count)
    }

    /// Time spent playing, not counting pauses.
    var elapsed: TimeInterval {
        activeSeconds + (resumedAt.map { clock().timeIntervalSince($0) } ?? 0)
    }

    private var languageCode: String {
        current?.languageCode ?? dependencies.settings.currentLanguageCode
    }

    // MARK: - Control

    func start() {
        guard startedAt == nil, !phrases.isEmpty else { return }
        startedAt = clock()
        try? dependencies.audioSession.activate(.backgroundRecall)
        let controls = dependencies.recallControls
        controls.onEvent = { [weak self] event in self?.handle(event) }
        controls.activate()
        resumeRunning()
    }

    func pause() {
        guard !isPaused, !isFinished, startedAt != nil else { return }
        isPaused = true
        if let resumedAt {
            activeSeconds += clock().timeIntervalSince(resumedAt)
        }
        resumedAt = nil
        run?.cancel()
        run = nil
        dependencies.speech.stop()
        updateNowPlaying()
    }

    func resume() {
        guard isPaused, !isFinished else { return }
        isPaused = false
        pausedBySystem = false
        resumeRunning()
    }

    func togglePause() {
        isPaused ? resume() : pause()
    }

    /// Swipe or the lock screen's next button.
    func skip() {
        guard !isFinished else { return }
        run?.cancel()
        run = nil
        dependencies.speech.stop()
        step = .english
        index += 1
        if index >= phrases.count {
            finish()
        } else if !isPaused {
            resumeRunning()
        } else {
            phase = .english
            updateNowPlaying()
        }
    }

    /// Ends the session early (leaving the screen).
    func stop() {
        guard !isFinished else {
            tearDown()
            return
        }
        finish()
    }

    // MARK: - Running

    private func resumeRunning() {
        resumedAt = clock()
        run?.cancel()
        run = Task { [weak self] in await self?.runLoop() }
    }

    private func runLoop() async {
        while let phrase = current {
            do {
                try await perform(step, for: phrase)
            } catch {
                return
            }
            if Task.isCancelled { return }
            switch step {
            case .english: step = .thinking
            case .thinking: step = .answer
            case .answer:
                practisedCount += 1
                step = .hold
            case .hold:
                step = .english
                index += 1
            }
        }
        finish()
    }

    private func perform(_ step: Step, for phrase: Phrase) async throws {
        let settings = dependencies.settings
        switch step {
        case .english:
            phase = .english
            updateNowPlaying()
            await dependencies.speech.speak(phrase.englishText, role: .english, speed: .natural)
        case .thinking:
            let gap = Duration.seconds(settings.thinkingGap)
            for dot in 0 ..< 3 {
                phase = .thinking(dots: dot + 1)
                try await sleep(gap / 3)
            }
        case .answer:
            phase = .answer
            let role = VoiceRole.target(phrase.languageCode)
            await dependencies.speech.speak(phrase.targetText, role: role, speed: settings.recallSpeed)
            if settings.playTranslationTwice, !Task.isCancelled {
                try await sleep(Self.pauseBetweenRepeats)
                await dependencies.speech.speak(phrase.targetText, role: role, speed: settings.recallSpeed)
            }
        case .hold:
            phase = .hold
            try await sleep(Self.holdAfterAnswer)
        }
        try Task.checkCancellation()
    }

    private func finish() {
        if let resumedAt {
            activeSeconds += clock().timeIntervalSince(resumedAt)
        }
        resumedAt = nil
        run?.cancel()
        run = nil
        phase = .finished
        finishedAt = clock()
        tearDown()
    }

    private func tearDown() {
        dependencies.speech.stop()
        dependencies.recallControls.deactivate()
        dependencies.audioSession.deactivate()
    }

    // MARK: - System events

    private func handle(_ event: RecallSystemEvent) {
        switch event {
        case .play:
            resume()
        case .pause:
            pause()
        case .togglePlayPause:
            togglePause()
        case .next:
            skip()
        case .interruptionBegan, .outputDisconnected:
            if !isPaused {
                pause()
                pausedBySystem = event == .interruptionBegan
            }
        case let .interruptionEnded(shouldResume):
            if shouldResume, pausedBySystem {
                resume()
            }
        }
    }

    private func updateNowPlaying() {
        guard let phrase = current else { return }
        let language = LanguageTheme.forCode(phrase.languageCode)?.displayName ?? ""
        dependencies.recallControls.update(
            title: phrase.englishText,
            subtitle: "Audio recall · \(language) · \(position) of \(phrases.count)",
            isPlaying: !isPaused
        )
    }
}
