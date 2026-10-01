import SwiftUI

/// A selectable capsule, e.g. a situation for suggested phrases. Solid,
/// because chips sit in content, not on controls.
struct Chip: View {
    private let title: String
    private let isSelected: Bool
    private let action: () -> Void

    @Environment(\.languageTheme) private var theme

    init(_ title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .appTextStyle(isSelected ? .subheadlineEmphasized : .subheadline)
                .foregroundStyle(isSelected ? theme.accentText : DS.Color.ink)
                .padding(.horizontal, DS.Spacing.m - 2)
                .padding(.vertical, DS.Spacing.xs + 1)
                .frame(minHeight: DS.Size.minTouch - DS.Spacing.xs)
                .background(isSelected ? theme.accentTint : DS.Color.surface, in: .capsule)
                .overlay {
                    Capsule().strokeBorder(isSelected ? theme.accent : DS.Color.hairline, lineWidth: DS.Size.hairlineWidth)
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack(alignment: .leading, spacing: DS.Spacing.l) {
        ForEach(LanguageTheme.all) { theme in
            FlowLayout {
                Chip("At the grocery store", isSelected: false) {}
                Chip("At a café or restaurant", isSelected: true) {}
                Chip("Directions", isSelected: false) {}
            }
            .languageTheme(theme)
        }
    }
    .padding(DS.Spacing.screenPadding)
}
