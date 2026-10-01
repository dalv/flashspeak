import SwiftUI

/// The app's root: the new Home.
///
/// DEBUG launch arguments: `-componentGallery` shows the design system;
/// `-legacyUI` shows the 1.x screens, kept until their replacements are
/// confirmed and the legacy code is deleted.
struct RootView: View {
    @Environment(\.appDependencies) private var dependencies
    @State private var navigateToPractice = false

    var body: some View {
        #if DEBUG
            if CommandLine.arguments.contains("-componentGallery") {
                ComponentGallery()
            } else if let demo = DemoScreen.requested {
                DemoScreen(name: demo.name, languageCode: demo.language)
            } else if CommandLine.arguments.contains("-legacyUI") {
                legacyHome
            } else {
                home
            }
        #else
            home
        #endif
    }

    @ViewBuilder
    private var home: some View {
        if let dependencies {
            if dependencies.settings.hasCompletedOnboarding {
                HomeScreen(dependencies: dependencies)
            } else {
                OnboardingScreen(dependencies: dependencies)
            }
        }
    }

    private var legacyHome: some View {
        HomeView(navigateToPractice: $navigateToPractice)
            .onReceive(NotificationCenter.default.publisher(for: .navigateToPractice)) { _ in
                navigateToPractice = true
            }
    }
}
