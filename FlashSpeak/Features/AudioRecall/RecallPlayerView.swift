import SwiftUI

/// The running session, on the dark recall ground: header, the current
/// step, progress and the hold/swipe hint. Touch and hold pauses; swipe
/// left skips.
struct RecallPlayerView: View {
    let session: RecallSession
    let onClose: () -> Void

    @Environment(\.languageTheme) private var theme
    @State private var pausedByHold = false

    var body: some View {
        VStack(spacing: DS.Spacing.l) {
            header
            stage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            footer
        }
        .padding(.horizontal, DS.Spacing.recallScreenPadding)
        .padding(.bottom, DS.Spacing.m)
        .background(DS.Color.recallGround.ignoresSafeArea())
        .contentShape(.rect)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 24, perform: {}, onPressingChanged: holdChanged)
        .simultaneousGesture(
            DragGesture(minimumDistance: 40).onEnded { value in
                if value.translation.width < -60, abs(value.translation.height) < 80 {
                    session.skip()
                }
            }
        )
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: session.isPaused ? "Resume" : "Pause") { session.togglePause() }
        .accessibilityAction(named: "Skip") { session.skip() }
        .environment(\.colorScheme, .dark)
    }

    private var header: some View {
        HStack {
            GlassIconButton("End session", systemImage: "xmark", action: onClose)
            Spacer()
            VStack(spacing: 0) {
                Text("Audio recall")
                    .appTextStyle(.subheadlineEmphasized)
                    .foregroundStyle(DS.Color.recallInk)
                Text(theme.displayName)
                    .appTextStyle(.footnote)
                    .foregroundStyle(DS.Color.recallInkSecondary)
            }
            Spacer()
            Text(speed.title)
                .appTextStyle(.captionEmphasized)
                .foregroundStyle(DS.Color.recallInk)
                .padding(.horizontal, DS.Spacing.s)
                .frame(height: DS.Size.compactButtonHeight)
                .background(DS.Color.recallTrack, in: .capsule)
        }
    }

    @ViewBuilder
    private var stage: some View {
        if let phrase = session.current {
            VStack(spacing: DS.Spacing.xxl) {
                switch session.phase {
                case .english:
                    VStack(spacing: DS.Spacing.s) {
                        Text("English")
                            .appTextStyle(.eyebrow)
                            .foregroundStyle(DS.Color.recallInkSecondary)
                        Text(phrase.englishText)
                            .appTextStyle(.recallPrompt)
                            .foregroundStyle(DS.Color.recallInk)
                    }
                    .transition(.opacity)
                case let .thinking(dots):
                    Text(phrase.englishText)
                        .appTextStyle(.recallPrompt)
                        .foregroundStyle(DS.Color.recallInk)
                    RecallThinkingDots(visible: dots)
                    Text("Say it out loud")
                        .appTextStyle(.secondary)
                        .foregroundStyle(DS.Color.recallInkSecondary)
                case .answer, .hold, .finished:
                    Text(phrase.englishText)
                        .appTextStyle(.body)
                        .foregroundStyle(DS.Color.recallInkSecondary)
                    VStack(spacing: DS.Spacing.xs) {
                        Text(phrase.targetText)
                            .nativeTextStyle(.recall, script: theme.script)
                            .foregroundStyle(theme.accentOnDark)
                        if let reading = phrase.reading {
                            Text(reading)
                                .nativeTextStyle(.reading, script: theme.script)
                                .foregroundStyle(DS.Color.recallInkSecondary)
                        }
                        if !phrase.pronunciation.isEmpty {
                            Text(phrase.pronunciation)
                                .appTextStyle(.romanization)
                                .foregroundStyle(DS.Color.recallInk)
                        }
                    }
                    .transition(.opacity)
                    if session.phase == .answer {
                        Label(speed == .natural ? "Speaking" : "Speaking slowly", systemImage: "speaker.wave.2")
                            .appTextStyle(.secondary)
                            .foregroundStyle(DS.Color.recallInkSecondary)
                    }
                }
            }
            .multilineTextAlignment(.center)
            .animation(.easeInOut(duration: 0.35), value: session.phase)
            .overlay(alignment: .bottom) {
                if session.isPaused {
                    pausedBadge
                }
            }
        }
    }

    private var pausedBadge: some View {
        Button {
            session.resume()
        } label: {
            Label("Paused · tap to resume", systemImage: "play.fill")
                .appTextStyle(.secondaryEmphasized)
                .foregroundStyle(DS.Color.recallInk)
                .padding(.horizontal, DS.Spacing.m)
                .frame(minHeight: DS.Size.minTouch)
        }
        .buttonStyle(.glass)
        .opacity(pausedByHold ? 0 : 1)
    }

    private var footer: some View {
        VStack(spacing: DS.Spacing.s) {
            ProgressView(value: Double(session.position), total: Double(max(session.phrases.count, 1)))
                .progressViewStyle(.linear)
                .tint(theme.accentOnDark)
            HStack {
                Text("\(Text("\(session.position)").foregroundStyle(DS.Color.recallInk).bold()) of \(session.phrases.count) this session")
                Spacer()
                Text("\(session.setCount) in set")
            }
            .appTextStyle(.footnote)
            .foregroundStyle(DS.Color.recallInkSecondary)
            Text("Hold anywhere to pause · swipe to skip")
                .appTextStyle(.footnote)
                .foregroundStyle(DS.Color.recallInkSecondary)
                .padding(.top, DS.Spacing.xxs)
        }
    }

    private var speed: PlaybackSpeed {
        session.speed
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
