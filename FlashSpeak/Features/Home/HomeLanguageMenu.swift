import SwiftUI

/// The home toolbar's language switch: shows only the current language, in
/// its own script, and opens a menu of the four to change it.
struct HomeLanguageMenu: View {
    @Binding var languageCode: String

    private var theme: LanguageTheme {
        LanguageTheme.forCode(languageCode) ?? .mandarin
    }

    var body: some View {
        Menu {
            Picker("Language", selection: $languageCode) {
                ForEach(LanguageTheme.all) { option in
                    VStack {
                        Text(option.nativeName)
                        Text(option.displayName)
                    }
                    .tag(option.id)
                }
            }
        } label: {
            HStack(spacing: DS.Spacing.xxs) {
                Text(theme.nativeName)
                    .nativeTextStyle(.segment, script: theme.script)
                Image(systemName: "chevron.down")
                    .appTextStyle(.secondaryEmphasized)
                    .foregroundStyle(DS.Color.inkSecondary)
            }
            .foregroundStyle(DS.Color.ink)
        }
        .accessibilityLabel("Language")
        .accessibilityValue(theme.displayName)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    @Previewable @State var codes = ["zh-CN", "id", "ko", "ja"]

    NavigationStack {
        List(codes.indices, id: \.self) { index in
            HomeLanguageMenu(languageCode: $codes[index])
        }
    }
}
