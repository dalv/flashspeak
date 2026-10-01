/// Settings kept per language, on the device (decision 0009).
struct LanguageSettings: Codable, Hashable, Sendable {
    var register: Register = .casual
    /// The user's override of the set level, 1–6.
    var levelOverride: Int?
    var dailyNewCardLimit: Int = 10
}
