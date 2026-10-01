import AVFoundation
import NaturalLanguage
import Observation

/// `SpeechSynthesizer` on AVSpeechSynthesizer.
///
/// Slow lowers the speaking rate (pitch stays natural). Word by word splits
/// the text with NLTokenizer, so it works for scripts without spaces, and
/// speaks each word as its own utterance with a pause after it.
@MainActor
@Observable
final class AppleSpeechSynthesizer: NSObject, SpeechSynthesizer {
    private(set) var isSpeaking = false

    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private let voices: VoiceCatalog
    @ObservationIgnored private let audioSession: AudioSessionCoordinator
    @ObservationIgnored private var pending: [ObjectIdentifier: CheckedContinuation<Void, Never>] = [:]
    @ObservationIgnored private var wordHandlers: [ObjectIdentifier: (NSRange) -> Void] = [:]
    @ObservationIgnored private var generation = 0

    static let naturalRate = AVSpeechUtteranceDefaultSpeechRate
    static let slowRate = AVSpeechUtteranceDefaultSpeechRate * 0.72
    static let wordPause: TimeInterval = 0.35

    init(voices: VoiceCatalog, audioSession: AudioSessionCoordinator) {
        self.voices = voices
        self.audioSession = audioSession
        super.init()
        synthesizer.delegate = self
    }

    func speak(
        _ text: String,
        role: VoiceRole,
        speed: PlaybackSpeed,
        onWord: ((Range<String.Index>) -> Void)?
    ) async {
        stop()
        try? audioSession.activate(.playback)
        generation += 1
        let current = generation
        isSpeaking = true
        defer {
            if generation == current {
                isSpeaking = false
            }
        }

        let voice = voices.voice(for: role)
        switch speed {
        case .natural, .slow:
            let utterance = makeUtterance(text, voice: voice, rate: speed == .slow ? Self.slowRate : Self.naturalRate)
            await speak(utterance) { range in
                if let swiftRange = Range(range, in: text) {
                    onWord?(swiftRange)
                }
            }
        case .wordByWord:
            for word in Self.words(in: text, languageCode: role.languageCode) {
                guard generation == current else { return }
                let utterance = makeUtterance(String(text[word]), voice: voice, rate: Self.slowRate)
                utterance.postUtteranceDelay = Self.wordPause
                onWord?(word)
                await speak(utterance, onWord: nil)
            }
        }
    }

    func stop() {
        generation += 1
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        resumeAll()
        isSpeaking = false
    }

    /// Word ranges in `text`, using the language's word segmentation.
    static func words(in text: String, languageCode: String?) -> [Range<String.Index>] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        if let languageCode {
            tokenizer.setLanguage(NLLanguage(rawValue: languageCode == "zh-CN" ? "zh-Hans" : languageCode))
        }
        return tokenizer.tokens(for: text.startIndex ..< text.endIndex)
    }

    // MARK: - Private

    private func makeUtterance(_ text: String, voice: AVSpeechSynthesisVoice?, rate: Float) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = rate
        return utterance
    }

    private func speak(_ utterance: AVSpeechUtterance, onWord: ((NSRange) -> Void)?) async {
        await withCheckedContinuation { continuation in
            let id = ObjectIdentifier(utterance)
            pending[id] = continuation
            if let onWord {
                wordHandlers[id] = onWord
            }
            synthesizer.speak(utterance)
        }
    }

    private func finish(_ utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        wordHandlers[id] = nil
        pending.removeValue(forKey: id)?.resume()
    }

    private func resumeAll() {
        let continuations = pending.values
        pending.removeAll()
        wordHandlers.removeAll()
        continuations.forEach { $0.resume() }
    }
}

extension AppleSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        MainActor.assumeIsolated { finish(utterance) }
    }

    nonisolated func speechSynthesizer(_: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        MainActor.assumeIsolated { finish(utterance) }
    }

    nonisolated func speechSynthesizer(
        _: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        MainActor.assumeIsolated {
            wordHandlers[ObjectIdentifier(utterance)]?(characterRange)
        }
    }
}

private extension VoiceRole {
    var languageCode: String? {
        switch self {
        case .english: "en"
        case let .target(code): code
        }
    }
}
