import SwiftUI
import SwiftData

struct LanguageSettingView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.modelContext) private var modelContext
    @Query private var allPhrases: [Phrase]

    @State private var showingAddLanguage = false
    @State private var languageToRemove: Language?
    @State private var showingRemoveAlert = false

    var body: some View {
        List {
            Section {
                ForEach(settings.myLanguages) { language in
                    Button {
                        settings.setCurrentLanguage(language)
                    } label: {
                        HStack {
                            Text(language.flag)
                                .font(.title2)
                            Text(language.name)
                                .foregroundStyle(.primary)

                            Spacer()

                            if language.code == settings.currentLanguageCode {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        if settings.myLanguageCodes.count > 1 {
                            Button(role: .destructive) {
                                languageToRemove = language
                                showingRemoveAlert = true
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text("My Languages")
            } footer: {
                Text("Tap a language to make it active. Swipe to remove.")
            }
        }
        .navigationTitle("Languages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddLanguage = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddLanguage) {
            AddLanguageView()
        }
        .alert("Remove Language", isPresented: $showingRemoveAlert) {
            Button("Remove Language Only", role: .cancel) {
                if let language = languageToRemove {
                    settings.removeLanguage(language)
                }
            }
            Button("Remove Language & Cards", role: .destructive) {
                if let language = languageToRemove {
                    let cardsToDelete = allPhrases.filter { $0.languageCode == language.code }
                    for card in cardsToDelete {
                        modelContext.delete(card)
                    }
                    settings.removeLanguage(language)
                }
            }
        } message: {
            if let language = languageToRemove {
                let cardCount = allPhrases.filter { $0.languageCode == language.code }.count
                Text("You have \(cardCount) card(s) in \(language.name). Would you like to also delete them?")
            }
        }
    }
}

#Preview {
    NavigationStack {
        LanguageSettingView()
    }
    .modelContainer(for: Phrase.self, inMemory: true)
}
