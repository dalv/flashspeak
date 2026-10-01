import SwiftUI

/// A solid `ground` capsule for buttons inside a content card (e.g.
/// "Word by word" on the flashcard). Not glass, because it sits on content.
struct InlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .appTextStyle(.subheadlineEmphasized)
            .foregroundStyle(DS.Color.ink)
            .padding(.horizontal, DS.Spacing.m)
            .frame(minHeight: DS.Size.segmentHeight)
            .fixedSize(horizontal: true, vertical: false)
            .background(DS.Color.ground, in: .capsule)
            .opacity(configuration.isPressed ? DS.Size.pressedOpacity : 1)
            .contentShape(.capsule)
    }
}

extension ButtonStyle where Self == InlineButtonStyle {
    static var inline: InlineButtonStyle {
        InlineButtonStyle()
    }
}
