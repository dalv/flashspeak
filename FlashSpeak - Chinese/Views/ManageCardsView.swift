import SwiftUI
import SwiftData

struct ManageCardsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Phrase.createdAt, order: .reverse) private var phrases: [Phrase]
    
    @State private var showingDeleteAllAlert = false
    
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
            Text("This will permanently delete all \(phrases.count) cards. This cannot be undone.")
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
            
            // Delete All button at bottom
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
            
            Text(phrase.pinyin)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Text(phrase.hanzi)
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
        ChineseTTSService.shared.speak(phrase.hanzi)
    }
    
    private func deleteCards(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(phrases[index])
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
