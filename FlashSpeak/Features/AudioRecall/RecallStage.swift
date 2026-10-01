import SwiftUI

/// The current step of a recall session: the English, the thinking gap,
/// or the answer; with a resume button while paused.
///
/// The English prompt stays one view through the English and thinking
/// steps, so only the dots and the hint fade in.
struct RecallStage: View {
    let session: RecallSession
    /// False while the user holds the screen to pause.
    let showsPausedBadge: Bool

    var body: some View {
        if let phrase = session.current {
            VStack(spacing: DS.Spacing.xxl) {
                if isAnswer {
                    Text(phrase.englishText)
                        .appTextStyle(.body)
                        .foregroundStyle(DS.Color.recallInkSecondary)
                    RecallAnswer(phrase: phrase, isSpeaking: session.phase == .answer, speed: session.speed)
                        .transition(.opacity)
                } else {
                    VStack(spacing: DS.Spacing.s) {
                        Text("English")
                            .appTextStyle(.eyebrow)
                            .foregroundStyle(DS.Color.recallInkSecondary)
                        Text(phrase.englishText)
                            .appTextStyle(.recallPrompt)
                            .foregroundStyle(DS.Color.recallInk)
                    }
                    VStack(spacing: DS.Spacing.l) {
                        RecallThinkingDots(visible: dots)
                        Text("Say it out loud")
                            .appTextStyle(.secondary)
                            .foregroundStyle(DS.Color.recallInkSecondary)
                    }
                    .opacity(dots > 0 ? 1 : 0)
                }
            }
            .multilineTextAlignment(.center)
            .animation(.easeInOut(duration: 0.35), value: session.phase)
            .overlay(alignment: .bottom) {
                if session.isPaused {
                    RecallPausedBadge(action: session.resume)
                        .opacity(showsPausedBadge ? 1 : 0)
                }
            }
        }
    }

    private var isAnswer: Bool {
        switch session.phase {
        case .answer, .hold, .finished: true
        case .english, .thinking: false
        }
    }

    private var dots: Int {
        if case let .thinking(dots) = session.phase { dots } else { 0 }
    }
}
