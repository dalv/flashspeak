import SwiftUI

/// Three dots that appear one by one over the thinking gap.
struct RecallThinkingDots: View {
    let visible: Int

    var body: some View {
        HStack(spacing: DS.Spacing.s) {
            ForEach(0 ..< 3, id: \.self) { index in
                Circle()
                    .fill(DS.Color.recallInk)
                    .frame(width: DS.Spacing.s, height: DS.Spacing.s)
                    .opacity(index < visible ? 1 : 0.15)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: visible)
        .accessibilityHidden(true)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack(spacing: DS.Spacing.l) {
        RecallThinkingDots(visible: 1)
        RecallThinkingDots(visible: 3)
    }
    .padding()
    .background(DS.Color.recallGround)
}
