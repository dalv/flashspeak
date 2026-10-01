import SwiftUI

/// How to download Apple's Enhanced or Premium voice for a language.
struct BetterVoicesSheet: View {
    let languageName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                Text("iPhone has higher-quality \(languageName) voices you can download for free. They sound much more natural.")
                    .appTextStyle(.body)
                    .foregroundStyle(DS.Color.ink)
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    step(1, "Open Settings, then Accessibility.")
                    step(2, "Tap Read & Speak, then Voices.")
                    step(3, "Choose \(languageName) and download a voice marked Enhanced or Premium.")
                    step(4, "Come back to FlashSpeak. It uses the better voice automatically.")
                }
                Spacer()
                PrimaryButton("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            }
            .padding(DS.Spacing.screenPadding)
            .background(DS.Color.ground)
            .navigationTitle("Better voices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s) {
            Text("\(number)")
                .appTextStyle(.calloutEmphasized)
                .foregroundStyle(DS.Color.inkSecondary)
                .monospacedDigit()
            Text(text)
                .appTextStyle(.callout)
                .foregroundStyle(DS.Color.ink)
        }
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    BetterVoicesSheet(languageName: "Mandarin").languageTheme(.mandarin)
}

#Preview("Indonesian", traits: .modifier(DesignSystemPreview())) {
    BetterVoicesSheet(languageName: "Indonesian").languageTheme(.indonesian)
}

#Preview("Korean", traits: .modifier(DesignSystemPreview())) {
    BetterVoicesSheet(languageName: "Korean").languageTheme(.korean)
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    BetterVoicesSheet(languageName: "Japanese").languageTheme(.japanese).preferredColorScheme(.dark)
}
