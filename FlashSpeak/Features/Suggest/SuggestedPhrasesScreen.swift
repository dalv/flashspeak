import SwiftUI

/// The suggested phrases for a situation: they play in sequence at slow
/// speed; untick any you don't want, then save.
struct SuggestedPhrasesScreen: View {
    @Bindable var model: SuggestModel
    let onSaved: () -> Void

    @State private var savedCount: Int?
    @Environment(\.languageTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s) {
                ForEach(model.items) { item in
                    SuggestedPhraseCard(
                        item: item,
                        languageCode: model.languageCode,
                        isPlaying: model.items.firstIndex(of: item) == model.playingIndex,
                        isIncluded: Binding(
                            get: { model.items.first { $0.id == item.id }?.isIncluded ?? false },
                            set: { _ in model.toggle(item.id) }
                        ),
                        onPlay: { model.play(item.id) }
                    )
                }
                if model.isLoading {
                    ProgressView("Finding phrases at your level…")
                        .appTextStyle(.secondary)
                        .padding(DS.Spacing.xl)
                }
                if let error = model.errorMessage {
                    Text(error)
                        .appTextStyle(.secondary)
                        .foregroundStyle(DS.Color.danger)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.bottom, DS.Spacing.l)
        }
        .background(DS.Color.ground)
        .safeAreaBar(edge: .bottom) {
            HStack(spacing: DS.Spacing.s) {
                Button("\(SuggestModel.batchSize) more") {
                    Task { await model.loadBatch() }
                }
                .buttonStyle(.secondary)
                .disabled(model.isLoading)
                if let savedCount {
                    Label("Saved \(savedCount)", systemImage: "checkmark")
                        .appTextStyle(.headline)
                        .foregroundStyle(DS.Color.onAccent)
                        .frame(maxWidth: .infinity, minHeight: DS.Size.primaryButtonHeight)
                        .background(theme.accent, in: .capsule)
                } else {
                    PrimaryButton(saveTitle, action: save)
                        .disabled(model.includedCount == 0 || model.isLoading)
                }
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.s)
        }
        .navigationTitle(model.category)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(model.category)
                        .appTextStyle(.headline)
                        .foregroundStyle(DS.Color.ink)
                    if let index = model.playingIndex {
                        Text("Playing slowly · \(index + 1) of \(model.items.count)")
                            .appTextStyle(.footnote)
                            .foregroundStyle(DS.Color.inkSecondary)
                    }
                }
                .lineLimit(1)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(model.isPlaying ? "Pause" : "Play all", systemImage: model.isPlaying ? "pause.fill" : "play.fill", action: model.togglePlayAll)
                    .disabled(model.items.isEmpty)
            }
        }
        .sheet(isPresented: $model.showsPaywall) {
            PaywallScreen(onPurchased: { Task { await model.loadBatch() } })
        }
        .task {
            if model.items.isEmpty {
                await model.loadBatch()
            }
        }
        .onDisappear(perform: model.stopPlayback)
    }

    private var saveTitle: LocalizedStringKey {
        let count = model.includedCount
        return "Save \(count) phrase\(count == 1 ? "" : "s")"
    }

    private func save() {
        savedCount = model.save()
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            onSaved()
        }
    }
}
