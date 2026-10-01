import SwiftUI

extension EnvironmentValues {
    @Entry var languageTheme: LanguageTheme = .mandarin
}

extension View {
    /// Sets the language theme for this view and its children, and tints
    /// native controls (toggles, links, pickers) with the language's accent.
    func languageTheme(_ theme: LanguageTheme) -> some View {
        environment(\.languageTheme, theme)
            .tint(theme.accent)
    }
}
