import SwiftUI

/// The translated phrase: listen, explore the words, clarify, then save.
struct ResultScreen: View {
    @Bindable var model: ResultModel
    let onDiscard: () -> Void
    let onSaved: () -> Void

    @Environment(\.appDependencies) private var dependencies
    @State private var clarify: ClarifyModel?
    @State private var confirmsFlag = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("“\(model.english)”")
                    .appTextStyle(.body)
                    .foregroundStyle(DS.Color.inkSecondary)

                ResultDuplicateBanner(check: model.duplicate)

                PhraseCard(
                    content,
                    register: model.register.title,
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

                ResultVersionControls(model: model, onClarify: openClarify)
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.bottom, DS.Spacing.l)
        }
        .background(DS.Color.ground)
        .safeAreaBar(edge: .bottom) {
            ResultActionBar(model: model, onDiscard: onDiscard, onSave: save)
        }
        .navigationTitle("New phrase")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(
                    model.flagged ? "Reported" : "Report a bad translation",
                    systemImage: model.flagged ? "flag.fill" : "flag"
                ) {
                    confirmsFlag = true
                }
                .disabled(model.flagged)
                .tint(DS.Color.inkSecondary)
            }
        }
        .confirmationDialog("Report this translation?", isPresented: $confirmsFlag, titleVisibility: .visible) {
            Button("Report") { Task { await model.flag() } }
        } message: {
            Text("It's sent for review with the English and any clarifications. Thanks for helping improve translations.")
        }
        .sheet(item: $clarify) { clarify in
            ClarifySheet(model: clarify)
        }
        .task { model.playIfAutoPlay() }
    }

    private var content: PhraseContent {
        PhraseContent(
            english: model.english,
            native: model.current.targetText,
            reading: model.current.reading,
            romanization: model.current.romanization,
            level: model.levelLabel
        )
    }

    private func openClarify() {
        guard let dependencies else { return }
        clarify = ClarifyModel(result: model, dependencies: dependencies)
    }

    private func save() {
        model.save()
        if model.saveState == .saved {
            Task {
                try? await Task.sleep(for: .milliseconds(700))
                onSaved()
            }
        }
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    ResultScreenPreview(languageCode: "zh-CN", english: "Can you say that one more time, slowly?")
}

#Preview("Indonesian", traits: .modifier(DesignSystemPreview())) {
    ResultScreenPreview(languageCode: "id", english: "I'm already on my way.")
}

#Preview("Korean, dark", traits: .modifier(DesignSystemPreview())) {
    ResultScreenPreview(languageCode: "ko", english: "An iced Americano, please")
        .preferredColorScheme(.dark)
}

#Preview("Japanese", traits: .modifier(DesignSystemPreview())) {
    ResultScreenPreview(languageCode: "ja", english: "Could I get the check, please?")
}
