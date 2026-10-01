import Foundation
import Observation

/// The Clarify sheet: the user says or types what they meant, the Worker
/// returns candidates, and one of them replaces the result.
@MainActor
@Observable
final class ClarifyModel: Identifiable {
    enum Phase: Equatable {
        case input
        case sending
        case reply(ClarificationResult)
        case failed(String)
    }

    var mode: NewPhraseModel.Mode = .speak
    var typedText = ""
    let speech: SpeechInputModel
    private(set) var phase: Phase = .input
    /// The clarification text that produced the current reply.
    private(set) var sentText = ""

    @ObservationIgnored let result: ResultModel
    @ObservationIgnored private let dependencies: AppDependencies

    init(result: ResultModel, dependencies: AppDependencies) {
        self.result = result
        self.dependencies = dependencies
        speech = SpeechInputModel(service: dependencies.transcription)
    }

    var remaining: Int? {
        result.clarificationsRemaining
    }

    var isLimitReached: Bool {
        remaining == 0
    }

    /// The text that will be sent, from whichever input is active.
    var draft: String {
        (mode == .type ? typedText : speech.text).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSend: Bool {
        !draft.isEmpty && !isLimitReached && phase != .sending && !speech.isListening
    }

    func send() async {
        guard canSend else { return }
        let text = draft
        sentText = text
        phase = .sending
        let request = ClarificationRequest(
            english: result.english,
            language: result.languageCode,
            register: result.register,
            currentTargetText: result.current.targetText,
            currentRomanization: result.current.romanization,
            history: result.clarificationHistory,
            clarification: text
        )
        do {
            let reply = try await dependencies.translation.clarify(request)
            dependencies.usage.recordClarification(forPhrase: result.sessionKey)
            if reply.keepsCurrent {
                result.recordKept(clarification: text)
            }
            phase = .reply(reply)
        } catch {
            phase = .failed(error.userMessage)
        }
    }

    func use(_ candidate: TranslationResult) {
        result.apply(candidate, clarification: sentText)
    }

    func play(_ candidate: TranslationResult) {
        let speech = dependencies.speech
        let language = result.languageCode
        Task { await speech.speak(candidate.targetText, role: .target(language), speed: result.speed) }
    }

    /// Back to the input to try a different clarification.
    func tryAgain() {
        phase = .input
        typedText = ""
        speech.reset()
    }
}
