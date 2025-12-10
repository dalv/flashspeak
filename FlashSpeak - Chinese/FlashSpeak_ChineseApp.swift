import SwiftUI
import SwiftData

@main
struct FlashSpeakChineseApp: App {
    @State private var navigateToPractice = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Phrase.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Warm up Chinese TTS voice in background
        ChineseTTSService.shared.warmUp()
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.navigateToPractice, $navigateToPractice)
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
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
    
    // Handle notification tap
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

// MARK: - Notification Name Extension

extension Notification.Name {
    static let navigateToPractice = Notification.Name("navigateToPractice")
}

// MARK: - Environment Key for Navigation

private struct NavigateToPracticeKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var navigateToPractice: Binding<Bool> {
        get { self[NavigateToPracticeKey.self] }
        set { self[NavigateToPracticeKey.self] = newValue }
    }
}
