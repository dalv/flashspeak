import SwiftUI

/// Spaced-repetition review: front, flip, back, rate Hard or Easy.
struct FlashcardsScreen: View {
    @State private var model: FlashcardsModel
    private let onAudioRecall: () -> Void

    init(dependencies: AppDependencies, onAudioRecall: @escaping () -> Void) {
        _model = State(initialValue: FlashcardsModel(dependencies: dependencies))
        self.onAudioRecall = onAudioRecall
    }

    init(model: FlashcardsModel, onAudioRecall: @escaping () -> Void = {}) {
        _model = State(initialValue: model)
        self.onAudioRecall = onAudioRecall
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DS.Color.ground)
            .navigationTitle("Flashcards")
            .navigationSubtitle(model.isFinished ? "" : "\(model.remaining) left")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SectionMenu(selection: $model.section, sections: model.sections) {
                        Toggle("Listening first", systemImage: "ear", isOn: $model.isReversed)
                    }
                }
            }
            .languageTheme(LanguageTheme.forCode(model.languageCode) ?? .mandarin)
            .onAppear { if model.queue.isEmpty { model.load() } }
            .onDisappear { model.stopPlayback() }
    }

    @ViewBuilder
    private var content: some View {
        if let phrase = model.current {
            VStack(spacing: DS.Spacing.l) {
                if model.isFlipped {
                    FlashcardBack(
                        content: phrase.content,
                        gloss: phrase.gloss,
                        usageNote: phrase.usageNote,
                        isPlaying: model.isPlaying,
                        highlightedWord: model.highlightedWord,
                        onPlay: model.play,
                        onWordByWord: model.playWordByWord,
                        onWord: model.playWord(at:)
                    )
                    .transition(.opacity)

                    RatingButtons(
                        hardDetail: model.intervalText(for: .hard),
                        easyDetail: model.intervalText(for: .easy),
                        onHard: { withAnimation { model.rate(.hard) } },
                        onEasy: { withAnimation { model.rate(.easy) } }
                    )
                } else {
                    FlashcardFront(
                        english: phrase.englishText,
                        isReversed: model.isReversed,
                        isPlaying: model.isPlaying,
                        onPlay: model.play,
                        onFlip: { withAnimation { model.flip() } }
                    )
                    .transition(.opacity)

                    PrimaryButton("Show answer") {
                        withAnimation { model.flip() }
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.bottom, DS.Spacing.m)
            .id(phrase.persistentModelID)
        } else {
            AllCaughtUpView(
                reviewedCount: model.reviewedCount,
                nextDue: model.nextDue(),
                canPractise: !model.sections.isEmpty,
                onAudioRecall: onAudioRecall
            )
        }
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    NavigationStack {
        FlashcardsScreen(dependencies: dependencies) {}
    }
    .dependencies(dependencies)
}

#Preview("Indonesian, back", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "id"
    let model = FlashcardsModel(dependencies: dependencies)
    model.load()
    model.flip()
    return NavigationStack {
        FlashcardsScreen(model: model)
    }
    .dependencies(dependencies)
}

#Preview("Korean, listening first", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "ko"
    dependencies.settings.reverseFlashcards = true
    return NavigationStack {
        FlashcardsScreen(dependencies: dependencies) {}
    }
    .dependencies(dependencies)
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "ja"
    return NavigationStack {
        FlashcardsScreen(dependencies: dependencies) {}
    }
    .dependencies(dependencies)
    .preferredColorScheme(.dark)
}
