import SwiftUI

/// A toggle drawn as a round check mark, for including a suggested phrase.
/// Being a `Toggle`, VoiceOver reads it as a switch with its label.
struct CheckCircleToggleStyle: ToggleStyle {
    @Environment(\.languageTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            } icon: {
                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(configuration.isOn ? theme.accent : DS.Color.controlBorderStrong)
                    .appTextStyle(.title)
                    .contentTransition(.symbolEffect(.replace))
            }
            .labelStyle(.iconOnly)
            .frame(minWidth: DS.Size.minTouch, minHeight: DS.Size.minTouch)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? Text("On") : Text("Off"))
    }
}

extension ToggleStyle where Self == CheckCircleToggleStyle {
    static var checkCircle: CheckCircleToggleStyle {
        CheckCircleToggleStyle()
    }
}
