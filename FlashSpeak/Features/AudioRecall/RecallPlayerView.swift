import SwiftUI

/// The running session, on the dark recall ground: header, the current
/// step, progress and the hold/swipe hint. Touch and hold pauses; swipe
/// left skips.
struct RecallPlayerView: View {
    let session: RecallSession
    let onClose: () -> Void

    @State private var pausedByHold = false

    var body: some View {
        VStack(spacing: DS.Spacing.l) {
            RecallHeader(speed: session.speed, onClose: onClose)
            RecallStage(session: session, showsPausedBadge: !pausedByHold)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            RecallProgressFooter(position: session.position, total: session.phrases.count, setCount: session.setCount)
        }
        .padding(.horizontal, DS.Spacing.recallScreenPadding)
        .padding(.bottom, DS.Spacing.m)
        .background(DS.Color.recallGround.ignoresSafeArea())
        .contentShape(.rect)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 24, perform: {}, onPressingChanged: holdChanged)
        .simultaneousGesture(DragGesture(minimumDistance: 40).onEnded(swipeEnded))
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: session.isPaused ? "Resume" : "Pause") { session.togglePause() }
        .accessibilityAction(named: "Skip") { session.skip() }
        .environment(\.colorScheme, .dark)
    }

    /// A left swipe skips to the next phrase.
    private func swipeEnded(_ value: DragGesture.Value) {
        if value.translation.width < -60, abs(value.translation.height) < 80 {
            session.skip()
        }
    }

    private func holdChanged(_ isPressing: Bool) {
        if isPressing, !session.isPaused {
            pausedByHold = true
            session.pause()
        } else if !isPressing, pausedByHold {
            pausedByHold = false
            session.resume()
        }
    }
}
