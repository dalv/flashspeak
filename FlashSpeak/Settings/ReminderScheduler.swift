import Foundation
import UserNotifications

/// Schedules the daily practice reminder. Replaces the legacy
/// `NotificationManager` once Settings is rebuilt.
@MainActor
protocol ReminderScheduler: AnyObject {
    /// Asks for notification permission if needed. Returns whether allowed.
    func requestAuthorization() async -> Bool
    /// Replaces any scheduled reminder. `prompt` is an English phrase to
    /// recall, shown in the notification.
    func schedule(at time: ReminderTime, languageName: String, prompt: String?) async
    func cancel()
}

@MainActor
final class NotificationReminderScheduler: ReminderScheduler {
    static let identifier = "daily-practice"
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    func schedule(at time: ReminderTime, languageName: String, prompt: String?) async {
        cancel()
        let content = UNMutableNotificationContent()
        content.title = "Time to practise your \(languageName)"
        content.body = prompt.map { "How do you say “\($0)”?" } ?? "A few minutes of flashcards keeps it fresh."
        content.sound = .default
        // Read by the app delegate, which posts `.navigateToPractice`.
        content.userInfo = ["action": "practice"]

        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger))
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
    }
}

/// Records what was scheduled; for Previews and tests.
@MainActor
final class FakeReminderScheduler: ReminderScheduler {
    var allowsNotifications = true
    private(set) var scheduled: (time: ReminderTime, languageName: String, prompt: String?)?

    nonisolated init() {}

    func requestAuthorization() async -> Bool {
        allowsNotifications
    }

    func schedule(at time: ReminderTime, languageName: String, prompt: String?) async {
        scheduled = (time, languageName, prompt)
    }

    func cancel() {
        scheduled = nil
    }
}
