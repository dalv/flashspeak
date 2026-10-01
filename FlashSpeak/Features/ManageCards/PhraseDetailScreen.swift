import SwiftUI

/// The full card of a saved phrase: listen, explore the words, clarify,
/// try another version or edit. Changes keep the schedule and history.
struct PhraseDetailScreen: View {
    let phrase: Phrase
    let onDelete: () -> Void

    @State private var model: ResultModel
    @State private var clarify: ClarifyModel?
    @State private var editing = false
    @State private var confirmsDelete = false

    private let dependencies: AppDependencies

    init(phrase: Phrase, dependencies: AppDependencies, onDelete: @escaping () -> Void) {
        self.phrase = phrase
        self.dependencies = dependencies
        self.onDelete = onDelete
        _model = State(initialValue: ResultModel(editing: phrase, dependencies: dependencies))
    }

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("“\(phrase.englishText)”")
                    .appTextStyle(.body)
                    .foregroundStyle(DS.Color.inkSecondary)

                PhraseCard(
                    phrase.content,
                    isPlaying: model.isPlaying,
                    onPlay: model.play,
                    controls: {
                        SegmentedControl(selection: $model.speed, options: PlaybackSpeed.allCases, variant: .inline) {
                            Text($0.title)
                        }
                    },
                    footer: {
                        if !model.current.gloss.isEmpty {
                            Divider().overlay(DS.Color.hairline)
                            ResultWordGrid(gloss: model.current.gloss, highlighted: model.highlightedWord, onTap: model.playWord)
                        }
                        ResultNotes(alternative: model.current.alternative, usageNote: model.current.usageNote)
                    }
                )

                if phrase.isPreset {
                    Text("A preset card. Its text comes with the app.")
                        .appTextStyle(.secondary)
                        .foregroundStyle(DS.Color.inkSecondary)
                } else {
                    ResultVersionControls(model: model, onClarify: openClarify)
                    Button {
                        Task { await model.retry() }
                    } label: {
                        if model.isRetrying {
                            ProgressView()
                        } else {
                            Label("Try another version", systemImage: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(.secondary)
                    .disabled(model.isRetrying)
                }

                ReviewSummary(phrase: phrase)
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.bottom, DS.Spacing.l)
        }
        .background(DS.Color.ground)
        .navigationTitle("Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("More", systemImage: "ellipsis") {
                    if !phrase.isPreset {
                        Button("Edit", systemImage: "pencil") { editing = true }
                        Button("Delete", systemImage: "trash", role: .destructive) { confirmsDelete = true }
                    }
                }
                .tint(DS.Color.ink)
                .disabled(phrase.isPreset)
                .confirmationDialog("Delete this phrase?", isPresented: $confirmsDelete, titleVisibility: .visible) {
                    Button("Delete", role: .destructive, action: onDelete)
                }
            }
        }
        .sheet(item: $clarify) { clarify in
            ClarifySheet(model: clarify)
        }
        .sheet(isPresented: $editing, onDismiss: reloadModel) {
            PhraseEditSheet(phrase: phrase, dependencies: dependencies)
        }
        .onDisappear { dependencies.speech.stop() }
    }

    private func openClarify() {
        clarify = ClarifyModel(result: model, dependencies: dependencies)
    }

    /// After a manual edit, start from the edited text.
    private func reloadModel() {
        model = ResultModel(editing: phrase, dependencies: dependencies)
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    PhraseDetailPreview(languageCode: "zh-CN")
}

#Preview("Indonesian", traits: .modifier(DesignSystemPreview())) {
    PhraseDetailPreview(languageCode: "id")
}

#Preview("Korean", traits: .modifier(DesignSystemPreview())) {
    PhraseDetailPreview(languageCode: "ko")
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    PhraseDetailPreview(languageCode: "ja")
        .preferredColorScheme(.dark)
}

/// The first sample phrase in a language, on its full card.
private struct PhraseDetailPreview: View {
    let languageCode: String
    @State private var dependencies = AppDependencies.preview()

    var body: some View {
        let phrase = try? dependencies.phrases.phrases(in: languageCode, section: .all, sort: .newest).first
        NavigationStack {
            if let phrase {
                PhraseDetailScreen(phrase: phrase, dependencies: dependencies) {}
            }
        }
        .dependencies(dependencies)
        .languageTheme(LanguageTheme.forCode(languageCode) ?? .mandarin)
    }
}
