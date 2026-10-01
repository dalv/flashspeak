import Foundation

/// The daily reminder's time of day.
struct ReminderTime: Codable, Hashable, Sendable {
    var hour: Int
    var minute: Int

    /// 8 pm (PRD, Settings).
    static let `default` = ReminderTime(hour: 20, minute: 0)

    /// Today at this time, for a `DatePicker`.
    func date(on day: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        hour = components.hour ?? Self.default.hour
        minute = components.minute ?? Self.default.minute
    }
}
