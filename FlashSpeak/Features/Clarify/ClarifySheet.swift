import SwiftUI

/// Clarify: tell the app what you meant, in your own words, by voice or text.
struct ClarifySheet: View {
    @Bindable var model: ClarifyModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch model.phase {
                case .input:
                    input
                case .sending:
                    VStack(spacing: DS.Spacing.m) {
                        ProgressView()
                        Text("Working out what you meant…")
                            .appTextStyle(.secondary)
                            .foregroundStyle(DS.Color.inkSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case let .reply(reply):
                    ScrollView {
                        ClarifyReplyView(model: model, reply: reply) { dismiss() }
                            .padding(.horizontal, DS.Spacing.screenPadding)
                            .padding(.bottom, DS.Spacing.l)
                    }
                case let .failed(message):
                    VStack(spacing: DS.Spacing.m) {
                        Text(message)
                            .appTextStyle(.body)
                            .foregroundStyle(DS.Color.ink)
                            .multilineTextAlignment(.center)
                        Button("Try again", action: model.tryAgain)
                            .buttonStyle(.secondary)
                    }
                    .padding(DS.Spacing.screenPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(DS.Color.ground)
            .navigationTitle("Clarify")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark") {
                        model.speech.reset()
                        dismiss()
                    }
                    .tint(DS.Color.ink)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var input: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text("Not what you meant?")
                    .appTextStyle(.title)
                    .foregroundStyle(DS.Color.ink)
                Text("Say what's off in your own words. Sound out words you half-remember.")
                    .appTextStyle(.secondary)
                    .foregroundStyle(DS.Color.inkSecondary)
            }

            if model.mode != .speak || model.speech.state == .idle {
                ClarifyExamples { example in
                    model.typedText = example
                    model.mode = .type
                }
            }

            SegmentedControl(selection: $model.mode, options: [.speak, .type], variant: .glass) {
                Text($0.title)
            }

            if model.mode == .speak {
                SpeakInputView(
                    speech: model.speech,
                    prompt: "Say it in your own words",
                    primaryTitle: "Send",
                    isWorking: false,
                    onPrimary: send,
                    onTypeInstead: { model.mode = .type }
                )
            } else {
                TypeInputView(
                    text: $model.typedText,
                    placeholder: "e.g. it was something like…",
                    primaryTitle: "Send",
                    isWorking: false,
                    onPrimary: send
                )
            }

            if let remaining = model.remaining {
                Text(remaining == 0
                    ? "You've used the free clarifications for this phrase."
                    : "\(remaining) free clarification\(remaining == 1 ? "" : "s") left for this phrase")
                    .appTextStyle(.footnote)
                    .foregroundStyle(DS.Color.inkSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, DS.Spacing.screenPadding)
        .padding(.bottom, DS.Spacing.l)
        .disabled(model.isLimitReached)
    }

    private func send() {
        Task { await model.send() }
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    ClarifySheetPreview(languageCode: "zh-CN")
}

#Preview("Indonesian", traits: .modifier(DesignSystemPreview())) {
    ClarifySheetPreview(languageCode: "id")
}

#Preview("Korean", traits: .modifier(DesignSystemPreview())) {
    ClarifySheetPreview(languageCode: "ko")
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    ClarifySheetPreview(languageCode: "ja")
        .preferredColorScheme(.dark)
}

/// A clarify sheet over a fake result, for Previews.
private struct ClarifySheetPreview: View {
    let languageCode: String
    @State private var model: ClarifyModel?

    var body: some View {
        Group {
            if let model {
                ClarifySheet(model: model)
            }
        }
        .languageTheme(LanguageTheme.forCode(languageCode) ?? .mandarin)
        .task {
            let dependencies = AppDependencies.preview()
            dependencies.settings.currentLanguageCode = languageCode
            let english = "Let's take a taxi"
            if let translation = try? await FakeTranslationClient().translate(
                TranslationRequest(english: english, language: languageCode, register: .casual)
            ) {
                let result = ResultModel(english: english, source: .spoken, translation: translation, dependencies: dependencies)
                model = ClarifyModel(result: result, dependencies: dependencies)
            }
        }
    }
}
