/// Who speaks: English is always one male voice, each target language
/// always one female voice, so learners tell them apart by ear.
enum VoiceRole: Hashable, Sendable {
    case english
    /// A target language, by code (e.g. "zh-CN").
    case target(String)
}
