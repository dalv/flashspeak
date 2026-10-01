import SwiftUI

/// The phrase card as a translation result and as a flashcard back.
struct GalleryPhraseCardSection: View {
    let language: SampleLanguage

    @State private var speed = "Slow"
    @State private var isPlaying = false

    var body: some View {
        Section("Phrase card") {
            VStack(spacing: DS.Spacing.l) {
                PhraseCard(
                    language.phrases[0],
                    register: "Casual",
                    isPlaying: isPlaying,
                    onPlay: togglePlayback,
                    controls: {
                        SegmentedControl(selection: $speed, options: ["Natural", "Slow", "Word by word"], variant: .inline) {
                            Text($0)
                        }
                    }
                )

                PhraseCard(
                    language.phrases[1],
                    showsEnglish: true,
                    alignment: .center,
                    onPlay: {},
                    controls: {
                        Button("Word by word") {}
                            .buttonStyle(.inline)
                    }
                )
                .shadow(.card)
            }
            .padding(.vertical, DS.Spacing.s)
            .listRowBackground(DS.Color.ground)
            .listRowInsets(EdgeInsets())
        }
    }

    private func togglePlayback() {
        isPlaying.toggle()
    }
}
