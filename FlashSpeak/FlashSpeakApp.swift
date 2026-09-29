import SwiftUI
import SwiftData

@main
struct FlashSpeakApp: App {
    @State private var navigateToPractice = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Phrase.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.vladtamas.FlashSpeak")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Warm up TTS voice in background
        TTSService.shared.warmUp()
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            HomeView(navigateToPractice: $navigateToPractice)
                .onReceive(NotificationCenter.default.publisher(for: .navigateToPractice)) { _ in
                    navigateToPractice = true
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        if response.notification.request.content.userInfo["action"] as? String == "practice" {
            await MainActor.run {
                NotificationCenter.default.post(name: .navigateToPractice, object: nil)
            }
        }
    }
}

extension Notification.Name {
    static let navigateToPractice = Notification.Name("navigateToPractice")
}
