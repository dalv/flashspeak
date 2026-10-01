import SwiftUI

/// Under the card: "Not quite? Clarify", "Back to previous version", and
/// the latest clarification, so it's clear why the translation changed.
struct ResultVersionControls: View {
    let model: ResultModel
    let onClarify: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            if let last = model.clarifications.last {
                Text("You clarified: “\(last.text)”")
                    .appTextStyle(.secondary)
                    .foregroundStyle(DS.Color.inkSecondary)
            }
            if let error = model.retryError {
                Text(error)
                    .appTextStyle(.secondary)
                    .foregroundStyle(DS.Color.danger)
            }
            HStack(spacing: DS.Spacing.s) {
                Button("Not quite? Clarify", systemImage: "text.bubble", action: onClarify)
                    .buttonStyle(.secondary)
                    .accessibilityHint("Say or type what you meant, and get a better translation")
                if model.canGoBack {
                    Button("Previous", systemImage: "arrow.uturn.backward", action: model.backToPreviousVersion)
                        .buttonStyle(.secondary)
                        .accessibilityLabel("Back to previous version")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
