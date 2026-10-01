import SwiftUI

/// A full-width primary button with a loading state.
///
/// While loading, the title is replaced by a spinner, the button is
/// disabled, and VoiceOver still reads the title.
struct PrimaryButton: View {
    private let title: LocalizedStringKey
    private let isLoading: Bool
    private let action: () -> Void

    init(_ title: LocalizedStringKey, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: perform) {
            Text(title)
                .opacity(isLoading ? 0 : 1)
                .overlay {
                    if isLoading {
                        ProgressView()
                            .tint(DS.Color.onAccent)
                    }
                }
        }
        .buttonStyle(.primary)
        .accessibilityValue(isLoading ? Text("Loading") : Text(""))
    }

    /// Ignores taps (including VoiceOver activation) while loading, without
    /// the dimmed disabled look.
    private func perform() {
        guard !isLoading else { return }
        action()
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack(spacing: DS.Spacing.s) {
        ForEach(LanguageTheme.all) { theme in
            PrimaryButton("Save") {}
                .languageTheme(theme)
        }
        PrimaryButton("Translating", isLoading: true) {}
        PrimaryButton("Continue") {}
            .disabled(true)
        Button("Upgrade") {}
            .buttonStyle(.primaryCompact)
    }
    .padding(DS.Spacing.screenPadding)
}
