import SwiftUI

/// "Phrase deleted · Undo", shown for a few seconds after a delete.
struct UndoBar: View {
    let onUndo: () -> Void

    var body: some View {
        HStack {
            Text("Phrase deleted")
                .appTextStyle(.subheadline)
                .foregroundStyle(DS.Color.ink)
            Spacer()
            Button("Undo", action: onUndo)
                .buttonStyle(.inline)
        }
        .padding(.horizontal, DS.Spacing.m)
        .frame(minHeight: DS.Size.minTouch + DS.Spacing.xs)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, DS.Spacing.screenPadding)
        .padding(.bottom, DS.Spacing.xs)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack {
        Spacer()
        ForEach(LanguageTheme.all) { theme in
            UndoBar(onUndo: {}).languageTheme(theme)
        }
    }
}
