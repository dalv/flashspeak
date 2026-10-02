import SwiftUI

/// Flashcards and Audio recall, side by side: a plus when the category
/// isn't in that set, a checkmark when it is. Tapping asks to add or
/// remove, in a confirmation anchored to the button.
struct PresetSetButtons: View {
    let membership: PresetLibrary.Membership
    /// The change waiting for confirmation, if it's for this category.
    var pending: PresetCategoriesModel.PendingChange?
    let onTap: (PresetLibrary.ReviewSet) -> Void
    var onConfirm: () -> Void = {}
    var onDismiss: () -> Void = {}

    var body: some View {
        HStack(spacing: DS.Spacing.s) {
            button(.flashcards)
            button(.recall)
        }
    }

    private func button(_ set: PresetLibrary.ReviewSet) -> some View {
        let isIn = membership.contains(set)
        return Button(set.title, systemImage: isIn ? "checkmark" : "plus") { onTap(set) }
            .buttonStyle(PresetSetButtonStyle(isOn: isIn))
            .accessibilityLabel(isIn ? "Remove from \(set.title.lowercased())" : "Add to \(set.title.lowercased())")
            .accessibilityValue(isIn ? "Added" : "Not added")
            .confirmationDialog(
                pending?.title ?? "",
                isPresented: Binding(
                    get: { pending?.set == set },
                    set: { if !$0 { onDismiss() } }
                ),
                titleVisibility: .visible,
                presenting: pending
            ) { change in
                Button(change.confirmTitle, role: change.isAdding ? nil : .destructive, action: onConfirm)
            } message: { change in
                Text(change.message)
            }
    }
}

extension PresetLibrary.ReviewSet {
    var title: String {
        switch self {
        case .flashcards: "Flashcards"
        case .recall: "Audio recall"
        }
    }
}

/// A half-width capsule: filled accent when on, accent tint when off. Solid
/// rather than glass, because it sits on a content card.
private struct PresetSetButtonStyle: ButtonStyle {
    let isOn: Bool

    @Environment(\.languageTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .appTextStyle(.subheadlineEmphasized)
            .foregroundStyle(isOn ? DS.Color.onAccent : theme.accentText)
            .padding(.horizontal, DS.Spacing.s)
            .frame(maxWidth: .infinity, minHeight: DS.Size.compactButtonHeight)
            .background(isOn ? theme.accent : theme.accentTint, in: .capsule)
            .opacity(configuration.isPressed ? DS.Size.pressedOpacity : 1)
            .contentShape(.capsule)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    let states: [PresetLibrary.Membership] = [
        .init(),
        .init(flashcards: true),
        .init(recall: true),
        .init(flashcards: true, recall: true),
    ]
    VStack(spacing: DS.Spacing.l) {
        ForEach(Array(zip(LanguageTheme.all, states)), id: \.0.id) { theme, membership in
            PresetSetButtons(membership: membership) { _ in }
                .languageTheme(theme)
        }
    }
    .padding(DS.Spacing.screenPadding)
}
