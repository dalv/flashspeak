import SwiftUI

/// A Liquid Glass capsule for secondary actions (Discard, Retry, 5 more,
/// Show answer). Glass gives its own pressed feedback.
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .appTextStyle(.calloutEmphasized)
            .foregroundStyle(isEnabled ? DS.Color.ink : DS.Color.inkSecondary)
            .padding(.horizontal, DS.Spacing.l)
            .frame(minHeight: DS.Size.primaryButtonHeight)
            .fixedSize(horizontal: true, vertical: false)
            .contentShape(.capsule)
            .glassEffect(.regular.interactive(), in: .capsule)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle {
        SecondaryButtonStyle()
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack(spacing: DS.Spacing.l) {
        ForEach(LanguageTheme.all) { theme in
            HStack(spacing: DS.Spacing.s) {
                Button("Discard") {}
                    .buttonStyle(.secondary)
                Button("Retry", systemImage: "arrow.clockwise") {}
                    .buttonStyle(.secondary)
                PrimaryButton("Save") {}
            }
            .languageTheme(theme)
        }
        Button("Show answer") {}
            .buttonStyle(.secondary)
    }
    .padding(DS.Spacing.screenPadding)
}
