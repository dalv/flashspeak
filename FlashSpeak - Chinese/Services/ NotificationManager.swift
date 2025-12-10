import Foundation
import UserNotifications
import SwiftData

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    func scheduleDaily(at hour: Int, minute: Int, phrases: [Phrase]) {
        // Remove existing notifications first
        cancelAll()
        
        guard !phrases.isEmpty else { return }
        
        // Pick a random phrase for the notification
        let phrase = phrases.randomElement()!
        
        let content = UNMutableNotificationContent()
        content.title = "Time to practice! 🇨🇳"
        content.body = "How do you say: \"\(phrase.englishText)\"?"
        content.sound = .default
        content.userInfo = ["action": "practice"]
        
        // Create daily trigger
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily-practice",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// Refreshes the notification with a new random phrase (call this after practice or adding new phrases)
    func refreshNotification(hour: Int, minute: Int, phrases: [Phrase]) {
        guard isAuthorized else { return }
        scheduleDaily(at: hour, minute: minute, phrases: phrases)
    }
}
