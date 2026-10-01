import SwiftUI

/// One language to choose on first launch, in its own script and accent.
struct OnboardingLanguageOption: View {
    let theme: LanguageTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.m) {
                VStack(alignment: .leading, spacing: DS.Spacing.xxs / 2) {
                    Text(theme.nativeName)
                        .nativeTextStyle(.row, script: theme.script)
                        .foregroundStyle(DS.Color.ink)
                    Text(theme.displayName)
                        .appTextStyle(.secondary)
                        .foregroundStyle(DS.Color.inkSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .appTextStyle(.title)
                    .foregroundStyle(isSelected ? theme.accent : DS.Color.controlBorderStrong)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, DS.Spacing.m)
            .frame(minHeight: DS.Size.ratingButtonHeight)
            .background(isSelected ? theme.accentTint : DS.Color.surface, in: .rect(cornerRadius: DS.Radius.list, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.list, style: .continuous)
                    .strokeBorder(isSelected ? theme.accent : DS.Color.hairline, lineWidth: DS.Size.hairlineWidth)
            }
            .contentShape(.rect(cornerRadius: DS.Radius.list))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
