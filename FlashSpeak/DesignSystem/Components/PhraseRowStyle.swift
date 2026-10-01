/// How a `PhraseRow` orders its text.
enum PhraseRowStyle: Sendable {
    /// English first, then native and romanization on one line.
    /// For Manage cards, where you scan by meaning.
    case englishFirst
    /// Native script first and large, then romanization, then English.
    /// For suggested phrases, where you are hearing the target language.
    case nativeFirst
}
