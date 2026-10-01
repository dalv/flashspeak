import Foundation

/// The short "when it comes back" text under a rating button.
enum ReviewIntervalText {
    static func text(from now: Date, to due: Date, calendar: Calendar = .current) -> String {
        let seconds = due.timeIntervalSince(now)
        if seconds < 60 * 60 {
            return "Again soon"
        }
        if calendar.isDate(due, inSameDayAs: now) {
            return "Later today"
        }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: due)
        ).day ?? 0
        switch days {
        case ..<2:
            return "Tomorrow"
        case ..<30:
            return "In \(days) days"
        case ..<365:
            let months = max(days / 30, 1)
            return months == 1 ? "In 1 month" : "In \(months) months"
        default:
            let years = max(days / 365, 1)
            return years == 1 ? "In 1 year" : "In \(years) years"
        }
    }
}
