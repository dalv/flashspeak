import SwiftUI

struct AddLanguageView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = SettingsManager.shared

    @State private var searchText = ""

    private var availableLanguages: [Language] {
        let existing = Set(settings.myLanguageCodes)
        let filtered = Language.allLanguages.filter { !existing.contains($0.code) }

        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(availableLanguages) { language in
                Button {
                    settings.addLanguage(language)
                    settings.setCurrentLanguage(language)
                    dismiss()
                } label: {
                    HStack {
                        Text(language.flag)
                            .font(.title2)
                        Text(language.name)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search languages")
            .navigationTitle("Add Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddLanguageView()
}
