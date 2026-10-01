import Foundation
import Observation

/// `UsageService` counted in `UserDefaults`. The daily count resets at local
/// midnight. Pro users are unlimited.
@MainActor
@Observable
final class LocalUsageService: UsageService {
    static let dailyTranslations = 3
    static let clarificationsPerPhrase = 3

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let isPro: @MainActor () -> Bool
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let calendar: Calendar

    /// Bumped on every change so observers re-read the counts.
    private var revision = 0

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init,
        isPro: @escaping @MainActor () -> Bool
    ) {
        self.defaults = defaults
        self.calendar = calendar
        self.now = now
        self.isPro = isPro
    }

    var translationsRemainingToday: Int? {
        _ = revision
        guard !isPro() else { return nil }
        return max(Self.dailyTranslations - translationsUsedToday, 0)
    }

    func recordTranslation() {
        defaults.set(translationsUsedToday + 1, forKey: Keys.count)
        defaults.set(todayKey, forKey: Keys.day)
        revision += 1
    }

    func clarificationsRemaining(forPhrase key: String) -> Int? {
        _ = revision
        guard !isPro() else { return nil }
        return max(Self.clarificationsPerPhrase - clarifications[key, default: 0], 0)
    }

    func recordClarification(forPhrase key: String) {
        var counts = clarifications
        counts[key, default: 0] += 1
        defaults.set(counts, forKey: Keys.clarifications)
        revision += 1
    }

    // MARK: - Private

    private var translationsUsedToday: Int {
        defaults.string(forKey: Keys.day) == todayKey ? defaults.integer(forKey: Keys.count) : 0
    }

    private var clarifications: [String: Int] {
        defaults.dictionary(forKey: Keys.clarifications) as? [String: Int] ?? [:]
    }

    private var todayKey: String {
        let parts = calendar.dateComponents([.year, .month, .day], from: now())
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    private enum Keys {
        static let day = "usage.v2.day"
        static let count = "usage.v2.translations"
        static let clarifications = "usage.v2.clarifications"
    }
}
