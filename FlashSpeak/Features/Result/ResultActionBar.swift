import SwiftUI

/// Discard, try another version, and Save (the screen's one filled button).
/// In one row when it fits; at large text sizes Save goes on its own row.
struct ResultActionBar: View {
    let model: ResultModel
    let onDiscard: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            if case let .failed(message) = model.saveState {
                Text(message)
                    .appTextStyle(.secondary)
                    .foregroundStyle(DS.Color.danger)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: DS.Spacing.s) {
                    ResultSecondaryActions(model: model, onDiscard: onDiscard)
                    ResultSaveButton(model: model, onSave: onSave)
                }
                VStack(spacing: DS.Spacing.s) {
                    ResultSaveButton(model: model, onSave: onSave)
                    HStack(spacing: DS.Spacing.s) {
                        ResultSecondaryActions(model: model, onDiscard: onDiscard)
                    }
                }
            }
        }
        .padding(.horizontal, DS.Spacing.screenPadding)
        .padding(.vertical, DS.Spacing.s)
    }
}

/// Discard and Retry.
private struct ResultSecondaryActions: View {
    let model: ResultModel
    let onDiscard: () -> Void

    var body: some View {
        Button("Discard", action: onDiscard)
            .buttonStyle(.secondary)
        Button {
            Task { await model.retry() }
        } label: {
            if model.isRetrying {
                ProgressView()
            } else {
                Label("Retry", systemImage: "arrow.clockwise")
            }
        }
        .buttonStyle(.secondary)
        .disabled(model.isRetrying)
        .accessibilityLabel("Try another version")
    }
}

/// Save, then a "Saved" confirmation in its place.
private struct ResultSaveButton: View {
    let model: ResultModel
    let onSave: () -> Void

    @Environment(\.languageTheme) private var theme

    var body: some View {
        if !model.canSave {
            Label("Already saved", systemImage: "checkmark")
                .appTextStyle(.headline)
                .foregroundStyle(DS.Color.inkSecondary)
                .frame(maxWidth: .infinity, minHeight: DS.Size.primaryButtonHeight)
                .background(DS.Color.surface, in: .capsule)
        } else if model.saveState == .saved {
            Label("Saved", systemImage: "checkmark")
                .appTextStyle(.headline)
                .foregroundStyle(DS.Color.onAccent)
                .frame(maxWidth: .infinity, minHeight: DS.Size.primaryButtonHeight)
                .background(theme.accent, in: .capsule)
        } else {
            PrimaryButton(model.duplicate == .none ? "Save" : "Save anyway", isLoading: model.saveState == .saving, action: onSave)
        }
    }
}
