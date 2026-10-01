import SwiftUI

/// Type input: a text field with the keyboard open and one action.
struct TypeInputView: View {
    @Binding var text: String
    let placeholder: String
    let primaryTitle: String
    let isWorking: Bool
    let onPrimary: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: DS.Spacing.l) {
            TextField(placeholder, text: $text, axis: .vertical)
                .appTextStyle(.body)
                .foregroundStyle(DS.Color.ink)
                .lineLimit(3 ... 8)
                .focused($isFocused)
                .submitLabel(.go)
                .onSubmit(onPrimary)
                .padding(DS.Spacing.m)
                .background(DS.Color.surface, in: .rect(cornerRadius: DS.Radius.field, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.field, style: .continuous)
                        .strokeBorder(DS.Color.hairline, lineWidth: DS.Size.hairlineWidth)
                }
            Spacer(minLength: 0)
            PrimaryButton(LocalizedStringKey(primaryTitle), isLoading: isWorking, action: onPrimary)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .onAppear { isFocused = true }
    }
}
