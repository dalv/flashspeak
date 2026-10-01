#if DEBUG
    import SwiftUI

    /// DEBUG only: opens one screen in a given state with preview data, for
    /// screenshots. Launch with `-demo <name> [-demoLanguage <code>]`.
    /// Names: home, onboarding, paywall, speak, listening, type, suggest,
    /// suggested, result, clarify, clarifyReply, duplicate, flashcards,
    /// flashcardBack, caughtUp, recall, recallThinking, recallAnswer, manage,
    /// card, presets, presetDetail.
    struct DemoScreen: View {
        let name: String
        let languageCode: String

        @State private var dependencies: AppDependencies
        @State private var newPhrase: NewPhraseModel?
        @State private var clarify: ClarifyModel?
        @State private var flashcards: FlashcardsModel?
        @State private var recall: AudioRecallModel?

        init(name: String, languageCode: String) {
            self.name = name
            self.languageCode = languageCode
            // Set before any screen loads; preview settings persist between launches.
            let dependencies = AppDependencies.preview()
            dependencies.settings.currentLanguageCode = languageCode
            _dependencies = State(initialValue: dependencies)
        }

        static var requested: (name: String, language: String)? {
            let defaults = UserDefaults.standard
            guard let name = defaults.string(forKey: "demo") else { return nil }
            return (name, defaults.string(forKey: "demoLanguage") ?? "zh-CN")
        }

        var body: some View {
            ZStack {
                DS.Color.ground.ignoresSafeArea()
                switch name {
                case "home":
                    HomeScreen(dependencies: dependencies)
                case "onboarding":
                    OnboardingScreen(dependencies: dependencies)
                case "paywall":
                    Color.clear.sheet(isPresented: .constant(true)) { PaywallScreen(limitReached: true) }
                case "suggest":
                    if let newPhrase {
                        NewPhraseFlow(model: newPhrase)
                    }
                case "result", "duplicate":
                    ResultScreenPreview(languageCode: languageCode, english: Self.english(for: languageCode), seeded: name == "duplicate")
                case "clarify", "clarifyReply":
                    if let clarify {
                        ClarifySheet(model: clarify)
                    }
                case "flashcards", "flashcardBack", "caughtUp":
                    if let flashcards {
                        NavigationStack { FlashcardsScreen(model: flashcards) }
                    }
                case "recall", "recallThinking", "recallAnswer":
                    if let recall {
                        NavigationStack { AudioRecallScreen(model: recall) }
                    }
                case "presets":
                    NavigationStack { PresetCategoriesScreen(dependencies: dependencies) }
                case "presetDetail":
                    if let category = dependencies.presets.category("numbers", in: languageCode) {
                        let model = PresetCategoriesModel(dependencies: dependencies)
                        NavigationStack { PresetCategoryDetail(category: category, model: model).onAppear(perform: model.refresh) }
                    }
                case "manage":
                    NavigationStack { ManageCardsScreen(dependencies: dependencies) }
                case "card":
                    if let phrase = try? dependencies.phrases.phrases(in: languageCode, section: .all, sort: .newest).first {
                        NavigationStack { PhraseDetailScreen(phrase: phrase, dependencies: dependencies) {} }
                    }
                default:
                    if let newPhrase {
                        NewPhraseFlow(model: newPhrase)
                    }
                }
            }
            .dependencies(dependencies)
            .languageTheme(LanguageTheme.forCode(languageCode) ?? .mandarin)
            .task { await setUp() }
        }

        private func setUp() async {
            dependencies.settings.currentLanguageCode = languageCode
            switch name {
            case "clarify", "clarifyReply":
                let english = Self.english(for: languageCode)
                guard let translation = try? await FakeTranslationClient().translate(
                    TranslationRequest(english: english, language: languageCode, register: .casual)
                ) else { return }
                let result = ResultModel(english: english, source: .spoken, translation: translation, dependencies: dependencies)
                let model = ClarifyModel(result: result, dependencies: dependencies)
                clarify = model
                if name == "clarifyReply" {
                    model.mode = .type
                    model.typedText = "it was something like dai cha"
                    await model.send()
                }
            case "flashcards", "flashcardBack", "caughtUp":
                let model = FlashcardsModel(dependencies: dependencies)
                model.load()
                if name == "flashcardBack" {
                    model.flip()
                }
                if name == "caughtUp" {
                    while !model.isFinished {
                        model.flip()
                        model.rate(.easy)
                    }
                }
                flashcards = model
            case "recall", "recallThinking", "recallAnswer":
                let model = AudioRecallModel(dependencies: dependencies)
                model.refresh()
                if name != "recall" {
                    // Hold the session on one step: the answer skips the
                    // three thinking-gap sleeps, then every sleep waits.
                    var sleeps = name == "recallAnswer" ? 3 : 0
                    model.start(sleep: { _ in
                        if sleeps > 0 {
                            sleeps -= 1
                            return
                        }
                        try await Task.sleep(for: .seconds(3600))
                    })
                }
                recall = model
            default:
                let model = NewPhraseModel(dependencies: dependencies)
                if name == "type" {
                    model.mode = .type
                    model.typedText = Self.english(for: languageCode)
                }
                newPhrase = model
                if name == "listening" {
                    await model.speech.start()
                }
                if name == "suggest" || name == "suggested" {
                    model.mode = .suggest
                    model.select(category: "At a café or restaurant")
                }
                if name == "suggested" {
                    model.startSuggestions()
                }
            }
        }

        private static func english(for languageCode: String) -> String {
            switch languageCode {
            case "id": "I'm already on my way."
            case "ko": "An iced Americano, please"
            case "ja": "Could I get the check, please?"
            default: "Can you say that one more time, slowly?"
            }
        }
    }
#endif
