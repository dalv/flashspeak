import Foundation
import Observation

/// First launch: pick the first language, then explain the microphone.
@MainActor
@Observable
final class OnboardingModel {
    enum Step {
        case language
        case microphone
    }

    private(set) var step: Step = .language
    var languageCode: String
    private(set) var isRequesting = false

    @ObservationIgnored private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        languageCode = dependencies.settings.currentLanguageCode
    }

    /// Users upgrading from 1.x with phrases already know the app.
    static func isNeeded(dependencies: AppDependencies) -> Bool {
        guard !dependencies.settings.hasCompletedOnboarding else { return false }
        let hasPhrases = Language.supportedCodes.contains { code in
            !((try? dependencies.phrases.phrases(in: code, section: .all, sort: .newest)) ?? []).isEmpty
        }
        if hasPhrases {
            dependencies.settings.hasCompletedOnboarding = true
        }
        return !hasPhrases
    }

    var theme: LanguageTheme {
        LanguageTheme.forCode(languageCode) ?? .mandarin
    }

    func confirmLanguage() {
        dependencies.settings.currentLanguageCode = languageCode
        step = .microphone
    }

    func allowMicrophone() async {
        isRequesting = true
        _ = await dependencies.transcription.requestPermission()
        isRequesting = false
        finish()
    }

    func finish() {
        dependencies.settings.hasCompletedOnboarding = true
    }
}
