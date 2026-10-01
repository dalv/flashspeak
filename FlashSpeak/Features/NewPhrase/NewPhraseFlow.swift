import SwiftUI

/// The New phrase modal: input (speak, type, suggest), then the result card.
struct NewPhraseFlow: View {
    @Bindable var model: NewPhraseModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.languageTheme) private var theme

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.l) {
                SegmentedControl(selection: $model.mode, options: NewPhraseModel.Mode.allCases, variant: .glass) {
                    Text($0.title)
                }

                switch model.mode {
                case .speak:
                    SpeakInputView(
                        speech: model.speech,
                        prompt: "Say a phrase in English",
                        primaryTitle: "Translate",
                        isWorking: model.isTranslating,
                        onPrimary: { Task { await model.translateSpoken() } },
                        onTypeInstead: switchToType
                    )
                case .type:
                    TypeInputView(
                        text: $model.typedText,
                        placeholder: "Type a phrase in English",
                        primaryTitle: "Translate",
                        isWorking: model.isTranslating,
                        onPrimary: { Task { await model.translateTyped() } }
                    )
                case .suggest:
                    SuggestCategoriesView(model: model)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DS.Color.ground)
            .navigationTitle("New phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark", action: close)
                        .tint(DS.Color.ink)
                }
            }
            .navigationDestination(item: $model.result) { result in
                ResultScreen(model: result, onDiscard: discard, onSaved: close)
            }
            .navigationDestination(item: $model.suggestions) { suggestions in
                SuggestedPhrasesScreen(model: suggestions, onSaved: close)
            }
        }
        .sheet(isPresented: $model.showsPaywall) {
            PaywallScreen(limitReached: true) {
                Task { await model.translatePending() }
            }
        }
        .onChange(of: model.mode) { _, mode in
            if mode != .speak {
                model.speech.reset()
            }
        }
    }

    private func switchToType() {
        model.typedText = model.speech.text
        model.mode = .type
    }

    private func discard() {
        model.startOver()
    }

    private func close() {
        model.speech.reset()
        dismiss()
    }
}

#Preview("Speak, Mandarin", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    NewPhraseFlow(model: NewPhraseModel(dependencies: dependencies))
        .dependencies(dependencies)
        .languageTheme(.mandarin)
}

#Preview("Type, Indonesian", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    let model = NewPhraseModel(dependencies: dependencies)
    model.mode = .type
    model.typedText = "I'm already on my way"
    return NewPhraseFlow(model: model)
        .dependencies(dependencies)
        .languageTheme(.indonesian)
}

#Preview("Speak, Korean, dark", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    NewPhraseFlow(model: NewPhraseModel(dependencies: dependencies))
        .dependencies(dependencies)
        .languageTheme(.korean)
        .preferredColorScheme(.dark)
}

#Preview("Speak, Japanese", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    NewPhraseFlow(model: NewPhraseModel(dependencies: dependencies))
        .dependencies(dependencies)
        .languageTheme(.japanese)
}
