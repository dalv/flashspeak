import SwiftUI

/// Decorative bars that move while listening. Hidden from VoiceOver; still
/// under Reduce Motion.
struct ListeningWaveform: View {
    private let isActive: Bool

    @Environment(\.languageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(isActive: Bool) {
        self.isActive = isActive
    }

    var body: some View {
        TimelineView(.animation(paused: !isActive || reduceMotion)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: DS.Size.waveformBarWidth) {
                ForEach(0 ..< DS.Size.waveformBars, id: \.self) { index in
                    Capsule()
                        .fill(theme.accent)
                        .frame(width: DS.Size.waveformBarWidth, height: height(for: index, at: time))
                }
            }
            .frame(height: DS.Size.waveformHeight)
        }
        .opacity(isActive ? 1 : 0.3)
        .accessibilityHidden(true)
    }

    private func height(for index: Int, at time: TimeInterval) -> CGFloat {
        let i = Double(index)
        // A fixed contour, so the still version (Reduce Motion) looks like a waveform.
        let contour = 0.35 + 0.65 * abs(sin(i * 0.9) * cos(i * 0.37))
        let motion = isActive && !reduceMotion ? 0.55 + 0.45 * sin(time * 6 + i * 1.3) : 1
        return max(DS.Size.waveformBarWidth * 2, DS.Size.waveformHeight * contour * motion)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack(spacing: DS.Spacing.xl) {
        ForEach(LanguageTheme.all) { theme in
            ListeningWaveform(isActive: true)
                .languageTheme(theme)
        }
        ListeningWaveform(isActive: false)
    }
}
