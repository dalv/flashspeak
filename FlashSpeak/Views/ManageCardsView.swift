import SwiftUI
import SwiftData

struct ManageCardsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Phrase.createdAt, order: .reverse) private var allPhrases: [Phrase]

    @ObservedObject private var settings = SettingsManager.shared

    @State private var showingDeleteAllAlert = false

    private var language: Language { settings.currentLanguage }

    private var phrases: [Phrase] {
        allPhrases.filter { $0.languageCode == settings.currentLanguageCode }
    }

    var body: some View {
        VStack {
            if phrases.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .navigationTitle("Manage Cards")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete All Cards?", isPresented: $showingDeleteAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                deleteAllCards()
            }
        } message: {
            Text("This will permanently delete all \(phrases.count) \(language.name) cards. This cannot be undone.")
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "rectangle.stack.badge.minus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No cards yet")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Add phrases using the New Phrase button")
                .font(.body)
                .foregroundStyle(.tertiary)

            Spacer()
        }
    }

    private var listView: some View {
        VStack {
            List {
                ForEach(phrases) { phrase in
                    cardRow(phrase)
                }
                .onDelete(perform: deleteCards)
            }
            .listStyle(.plain)

            Button(action: { showingDeleteAllAlert = true }) {
                Text("Delete All Cards")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
    }

    private func cardRow(_ phrase: Phrase) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(phrase.englishText)
                .font(.headline)

            if language.hasPronunciationGuide, !phrase.pronunciation.isEmpty {
                Text(phrase.pronunciation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(phrase.targetText)
                    .font(.title3)

                Spacer()

                Button(action: { speakPhrase(phrase) }) {
                    Image(systemName: "speaker.wave.2")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.borderless)
            }

            Text("Next review: \(phrase.nextReviewAt.formatted(.relative(presentation: .named)))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func speakPhrase(_ phrase: Phrase) {
        TTSService.shared.speak(phrase.targetText, language: language)
    }

    private func deleteCards(at offsets: IndexSet) {
        let phrasesToDelete = offsets.map { phrases[$0] }
        for phrase in phrasesToDelete {
            modelContext.delete(phrase)
        }
    }

    private func deleteAllCards() {
        for phrase in phrases {
            modelContext.delete(phrase)
        }
    }
}

#Preview {
    NavigationStack {
        ManageCardsView()
    }
    .modelContainer(for: Phrase.self, inMemory: true)
}
