import SwiftUI

/// Start learning, Pause or Resume, depending on a category's status.
struct PresetStatusButton: View {
    let status: PresetLibrary.Status
    let onStart: () -> Void
    let onPause: () -> Void

    var body: some View {
        switch status {
        case .notStarted:
            Button("Start learning", action: onStart)
                .buttonStyle(.primaryCompact)
        case .learning:
            Button("Pause", systemImage: "pause", action: onPause)
                .buttonStyle(.secondary)
                .accessibilityHint("Takes these cards out of review and keeps your progress")
        case .paused:
            Button("Resume", systemImage: "play", action: onStart)
                .buttonStyle(.secondary)
        }
    }
}
