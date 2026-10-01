import SwiftUI

/// First launch: choose a language, then allow the microphone (with the
/// reason shown before the system prompt).
struct OnboardingScreen: View {
    @State private var model: OnboardingModel

    init(dependencies: AppDependencies) {
        _model = State(initialValue: OnboardingModel(dependencies: dependencies))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            switch model.step {
            case .language:
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("Which language are you learning?")
                        .appTextStyle(.largeTitle)
                        .foregroundStyle(DS.Color.ink)
                    Text("You can add the others any time.")
                        .appTextStyle(.body)
                        .foregroundStyle(DS.Color.inkSecondary)
                }
                VStack(spacing: DS.Spacing.s) {
                    ForEach(LanguageTheme.all) { theme in
                        OnboardingLanguageOption(theme: theme, isSelected: model.languageCode == theme.id) {
                            model.languageCode = theme.id
                        }
                    }
                }
                Spacer(minLength: 0)
                PrimaryButton("Continue", action: model.confirmLanguage)

            case .microphone:
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: DS.Size.heroMicButton * 0.4, weight: .semibold))
                        .foregroundStyle(DS.Color.onAccent)
                        .frame(width: DS.Size.heroMicButton, height: DS.Size.heroMicButton)
                        .background(model.theme.accent, in: .circle)
                        .accessibilityHidden(true)
                    Text("Say it in English")
                        .appTextStyle(.largeTitle)
                        .foregroundStyle(DS.Color.ink)
                    Text("FlashSpeak listens when you tap the microphone and turns your English into text on your iPhone. Nothing is recorded or sent anywhere except the text to translate.")
                        .appTextStyle(.body)
                        .foregroundStyle(DS.Color.inkSecondary)
                }
                Spacer(minLength: 0)
                VStack(spacing: DS.Spacing.s) {
                    PrimaryButton("Allow microphone", isLoading: model.isRequesting) {
                        Task { await model.allowMicrophone() }
                    }
                    Button("Not now", action: model.finish)
                        .buttonStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.screenPadding)
        .padding(.vertical, DS.Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DS.Color.ground)
        .languageTheme(model.theme)
        .animation(.default, value: model.step)
    }
}

#Preview("Language", traits: .modifier(DesignSystemPreview())) {
    OnboardingScreen(dependencies: .preview())
}

#Preview("Language, dark", traits: .modifier(DesignSystemPreview())) {
    OnboardingScreen(dependencies: .preview())
        .preferredColorScheme(.dark)
}
