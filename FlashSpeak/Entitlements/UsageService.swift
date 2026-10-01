/// Free-plan limits: translations per day and clarifications per phrase.
/// Counted on the device until the Worker counts them (decision 0010).
@MainActor
protocol UsageService: AnyObject {
    /// Nil for Pro (unlimited).
    var translationsRemainingToday: Int? { get }
    func recordTranslation()

    /// Nil for Pro (unlimited).
    func clarificationsRemaining(forPhrase key: String) -> Int?
    func recordClarification(forPhrase key: String)
}
