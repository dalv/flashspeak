import SwiftUI

/// "Paused · tap to resume", shown while a session is paused.
struct RecallPausedBadge: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Paused · tap to resume", systemImage: "play.fill")
                .appTextStyle(.secondaryEmphasized)
                .foregroundStyle(DS.Color.recallInk)
                .padding(.horizontal, DS.Spacing.m)
                .frame(minHeight: DS.Size.minTouch)
        }
        .buttonStyle(.glass)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    RecallPausedBadge {}
        .padding()
        .background(DS.Color.recallGround)
        .environment(\.colorScheme, .dark)
}
