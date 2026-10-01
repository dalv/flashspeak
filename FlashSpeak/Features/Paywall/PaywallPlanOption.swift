import SwiftUI

/// One plan in the paywall's radio group.
struct PaywallPlanOption: View {
    let title: String
    let price: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.languageTheme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.m) {
                VStack(alignment: .leading, spacing: DS.Spacing.xxs / 2) {
                    HStack(spacing: DS.Spacing.xs) {
                        Text(title)
                            .appTextStyle(.headline)
                            .foregroundStyle(DS.Color.ink)
                        if let badge {
                            Text(badge)
                                .appTextStyle(.captionEmphasized)
                                .foregroundStyle(DS.Color.onAccent)
                                .padding(.horizontal, DS.Spacing.xs)
                                .padding(.vertical, DS.Spacing.xxs / 2)
                                .background(theme.accent, in: .capsule)
                        }
                    }
                    Text(price)
                        .appTextStyle(.footnote)
                        .foregroundStyle(DS.Color.inkSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .appTextStyle(.title)
                    .foregroundStyle(isSelected ? theme.accent : DS.Color.controlBorderStrong)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, DS.Spacing.m)
            .frame(minHeight: DS.Size.ratingButtonHeight)
            .background(DS.Color.surface, in: .rect(cornerRadius: DS.Radius.list, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.list, style: .continuous)
                    .strokeBorder(
                        isSelected ? theme.accent : DS.Color.hairline,
                        lineWidth: isSelected ? DS.Size.selectedBorderWidth : DS.Size.hairlineWidth
                    )
            }
            .contentShape(.rect(cornerRadius: DS.Radius.list))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
