import Foundation
import Observation

/// The New phrase flow: the input mode, translating, and the result it opens.
@MainActor
@Observable
final class NewPhraseModel: Identifiable {
    enum Mode: String, CaseIterable, Hashable {
        case speak
        case type
        case suggest

        var title: String {
            switch self {
            case .speak: "Speak"
            case .type: "Type"
            case .suggest: "Suggest"
            }
        }
    }

    var mode: Mode = .speak
    var typedText = ""
    let speech: SpeechInputModel

    private(set) var isTranslating = false
    var errorMessage: String?
    /// Set when the free limit is reached; the phrase is kept in `pendingEnglish`.
    var showsPaywall = false
    private(set) var pendingEnglish: String?
    /// Pushes the result screen when set.
    var result: ResultModel?

    /// Suggest: the chosen situation, or the user's own description.
    private(set) var selectedCategory: String?
    var customCategory = "" {
        didSet { if !customCategory.isEmpty { selectedCategory = nil } }
    }
    /// Pushes the suggested-phrases screen when set.
    var suggestions: SuggestModel?

    @ObservationIgnored let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        speech = SpeechInputModel(service: dependencies.transcription)
    }

    var translationsRemaining: Int? {
        dependencies.usage.translationsRemainingToday
    }

    func translateSpoken() async {
        await translate(speech.text, source: .spoken)
    }

    func translateTyped() async {
        await translate(typedText, source: .typed)
    }

    /// Translates after an upgrade, if a phrase was waiting for the paywall.
    func translatePending() async {
        guard let pending = pendingEnglish else { return }
        await translate(pending, source: mode == .type ? .typed : .spoken)
    }

    func translate(_ text: String, source: PhraseSource) async {
        let english = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !english.isEmpty, !isTranslating else { return }

        if dependencies.usage.translationsRemainingToday == 0 {
            pendingEnglish = english
            showsPaywall = true
            return
        }

        isTranslating = true
        errorMessage = nil
        defer { isTranslating = false }

        let languageCode = dependencies.settings.currentLanguageCode
        let register = dependencies.settings.settings(for: languageCode).register
        do {
            let translation = try await dependencies.translation.translate(
                TranslationRequest(english: english, language: languageCode, register: register)
            )
            dependencies.usage.recordTranslation()
            pendingEnglish = nil
            result = ResultModel(english: english, source: source, translation: translation, dependencies: dependencies)
        } catch .limitReached {
            pendingEnglish = english
            showsPaywall = true
        } catch {
            errorMessage = error.userMessage
        }
    }

    // MARK: - Suggest

    var suggestionCategory: String? {
        let custom = customCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        return custom.isEmpty ? selectedCategory : custom
    }

    /// E.g. "TOPIK 1–2": the levels suggestions are generated at.
    var suggestionLevelRange: String {
        let code = dependencies.settings.currentLanguageCode
        return LevelScale.range(around: SuggestModel.setLevel(dependencies: dependencies, languageCode: code), languageCode: code)
    }

    func select(category: String) {
        customCategory = ""
        selectedCategory = selectedCategory == category ? nil : category
    }

    func startSuggestions() {
        guard let category = suggestionCategory else { return }
        suggestions = SuggestModel(category: category, dependencies: dependencies)
    }

    /// Clears the input after a phrase was saved or discarded.
    func startOver() {
        result = nil
        typedText = ""
        speech.reset()
    }
}
