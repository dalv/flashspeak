/// A language theme with sample phrases, for Previews.
struct SampleLanguage: Identifiable, Sendable {
    var id: String {
        theme.id
    }

    let theme: LanguageTheme
    /// At least four phrases.
    let phrases: [PhraseContent]
}
