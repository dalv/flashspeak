import SwiftUI

/// The one filled accent button on a screen (Save, Continue, Suggest).
///
/// A solid fill, not glass, so white text always meets contrast. Use
/// `.regular` for full-width bottom actions and `.compact` inside rows.
struct PrimaryButtonStyle: ButtonStyle {
    enum Size: Sendable {
        case regular
        case compact
    }

    var size: Size = .regular

    @Environment(\.languageTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .appTextStyle(size == .regular ? .headline : .subheadlineEmphasized)
            .foregroundStyle(DS.Color.onAccent)
            .padding(.horizontal, size == .regular ? DS.Spacing.l : DS.Spacing.m)
            .frame(
                maxWidth: size == .regular ? .infinity : nil,
                minHeight: size == .regular ? DS.Size.primaryButtonHeight : DS.Size.compactButtonHeight
            )
            .fixedSize(horizontal: size == .compact, vertical: false)
            .background(theme.accent, in: .capsule)
            .opacity(opacity(isPressed: configuration.isPressed))
            .contentShape(.capsule)
    }

    private func opacity(isPressed: Bool) -> Double {
        if !isEnabled {
            return DS.Size.disabledOpacity
        }
        return isPressed ? DS.Size.pressedOpacity : 1
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle {
        PrimaryButtonStyle()
    }

    static var primaryCompact: PrimaryButtonStyle {
        PrimaryButtonStyle(size: .compact)
    }
}
