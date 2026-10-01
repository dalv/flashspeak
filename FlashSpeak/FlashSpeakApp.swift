import SwiftUI
import SwiftData

@main
struct FlashSpeakApp: App {
    @State private var dependencies: AppDependencies

    init() {
        FontRegistration.registerBundledFonts()
        do {
            let dependencies = try AppDependencies.live()
            // Marks onboarding done for 1.x users who already have phrases.
            _ = OnboardingModel.isNeeded(dependencies: dependencies)
            _dependencies = State(initialValue: dependencies)
        } catch {
            fatalError("Could not open the phrase store: \(error)")
        }

        // Legacy: warm up TTS voice in background. Removed with the legacy views.
        TTSService.shared.warmUp()

        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .dependencies(dependencies)
        }
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
