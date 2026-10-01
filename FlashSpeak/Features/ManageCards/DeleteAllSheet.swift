import SwiftUI

/// Confirms deleting every phrase in a language by typing its name.
struct DeleteAllSheet: View {
    let languageName: String
    let count: Int
    let isValid: (String) -> Bool
    let onDelete: (String) -> Void

    @State private var typed = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                Text("This deletes all \(count) \(languageName) phrases and their review history. They can't be recovered after 30 days.")
                    .appTextStyle(.body)
                    .foregroundStyle(DS.Color.ink)

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("Type \(languageName) to confirm")
                        .appTextStyle(.sectionLabel)
                        .foregroundStyle(DS.Color.inkSecondary)
                    TextField(languageName, text: $typed)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .appTextStyle(.body)
                        .padding(DS.Spacing.s)
                        .background(DS.Color.surface, in: .rect(cornerRadius: DS.Radius.field))
                        .overlay {
                            RoundedRectangle(cornerRadius: DS.Radius.field)
                                .strokeBorder(DS.Color.controlBorder, lineWidth: DS.Size.hairlineWidth)
                        }
                }
                Spacer()

                Button(role: .destructive) {
                    onDelete(typed)
                    dismiss()
                } label: {
                    Text("Delete all \(languageName) phrases")
                        .appTextStyle(.headline)
                        .foregroundStyle(DS.Color.onAccent)
                        .frame(maxWidth: .infinity, minHeight: DS.Size.primaryButtonHeight)
                        .background(DS.Color.dangerFill, in: .capsule)
                }
                .buttonStyle(.plain)
                .disabled(!isValid(typed))
                .opacity(isValid(typed) ? 1 : DS.Size.disabledOpacity)
            }
            .padding(DS.Spacing.screenPadding)
            .background(DS.Color.ground)
            .navigationTitle("Delete all phrases")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    DeleteAllSheet(languageName: "Mandarin", count: 148, isValid: { $0 == "Mandarin" }, onDelete: { _ in })
        .languageTheme(.mandarin)
}

#Preview("Indonesian", traits: .modifier(DesignSystemPreview())) {
    DeleteAllSheet(languageName: "Indonesian", count: 32, isValid: { $0 == "Indonesian" }, onDelete: { _ in })
        .languageTheme(.indonesian)
}

#Preview("Korean", traits: .modifier(DesignSystemPreview())) {
    DeleteAllSheet(languageName: "Korean", count: 63, isValid: { $0 == "Korean" }, onDelete: { _ in })
        .languageTheme(.korean)
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    DeleteAllSheet(languageName: "Japanese", count: 12, isValid: { $0 == "Japanese" }, onDelete: { _ in })
        .languageTheme(.japanese)
        .preferredColorScheme(.dark)
}
