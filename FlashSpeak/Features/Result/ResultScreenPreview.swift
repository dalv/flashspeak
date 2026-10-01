import SwiftUI

/// Builds a result screen from the fake translation client, for Previews and
/// the DEBUG `-resultPreview` launch.
struct ResultScreenPreview: View {
    let languageCode: String
    let english: String
    /// With sample phrases in the store, so the duplicate check can match.
    var seeded = false

    @State private var model: ResultModel?
    @State private var dependencies: AppDependencies?

    var body: some View {
        NavigationStack {
            if let model, dependencies != nil {
                ResultScreen(model: model, onDiscard: {}, onSaved: {})
            } else {
                ProgressView()
            }
        }
        .environment(\.appDependencies, dependencies)
        .languageTheme(LanguageTheme.forCode(languageCode) ?? .mandarin)
        .task {
            let dependencies = AppDependencies.preview(isPro: true, seeded: seeded)
            self.dependencies = dependencies
            dependencies.settings.currentLanguageCode = languageCode
            let translation = try? await FakeTranslationClient().translate(
                TranslationRequest(english: english, language: languageCode, register: .casual)
            )
            if let translation {
                model = ResultModel(english: english, source: .spoken, translation: translation, dependencies: dependencies)
            }
        }
    }
}
