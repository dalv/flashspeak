import SwiftUI

/// Phrase rows as in Manage cards (native list rows with swipe actions)
/// and as suggested phrases (with the include toggle).
struct GalleryPhraseRowSection: View {
    let language: SampleLanguage

    @State private var included: Set<String> = []
    @State private var playingID: String?

    var body: some View {
        Section("Phrase rows · Manage cards") {
            ForEach(language.phrases) { phrase in
                PhraseRow(phrase, isPlaying: playingID == phrase.id) {
                    togglePlayback(phrase)
                }
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) {}
                        .tint(DS.Color.dangerFill)
                }
            }
        }
        .dsListRows()

        Section("Phrase rows · Suggested") {
            ForEach(language.phrases) { phrase in
                PhraseRow(
                    phrase,
                    style: .nativeFirst,
                    isPlaying: playingID == phrase.id,
                    isIncluded: includedBinding(for: phrase)
                ) {
                    togglePlayback(phrase)
                }
            }
        }
        .dsListRows()
        .onAppear(perform: includeAllButLast)
    }

    private func includedBinding(for phrase: PhraseContent) -> Binding<Bool> {
        Binding {
            included.contains(phrase.id)
        } set: { isOn in
            if isOn {
                included.insert(phrase.id)
            } else {
                included.remove(phrase.id)
            }
        }
    }

    private func togglePlayback(_ phrase: PhraseContent) {
        playingID = playingID == phrase.id ? nil : phrase.id
    }

    private func includeAllButLast() {
        included = Set(SampleContent.languages.flatMap { $0.phrases.dropLast().map(\.id) })
    }
}
