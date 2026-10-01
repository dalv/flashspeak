import SwiftUI

/// Glass, primary, secondary, rating and play buttons, and level labels.
///
/// Shown on `ground` (not in a card) because that's where controls sit.
struct GalleryButtonsSection: View {
    let language: SampleLanguage

    var body: some View {
        Section("Buttons") {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                HStack(spacing: DS.Spacing.s) {
                    GlassIconButton("Back", systemImage: "chevron.left") {}
                    GlassIconButton("Close", systemImage: "xmark") {}
                    GlassIconButton("Menu", systemImage: "line.3.horizontal") {}
                    GlassIconButton("Pause", systemImage: "pause.fill", isAccented: true) {}
                }

                HStack(spacing: DS.Spacing.s) {
                    Button("Discard") {}
                        .buttonStyle(.secondary)
                    Button("Retry", systemImage: "arrow.clockwise") {}
                        .buttonStyle(.secondary)
                    PrimaryButton("Save") {}
                }

                PrimaryButton("Suggest 5 phrases", isLoading: true) {}
                PrimaryButton("Continue") {}
                    .disabled(true)

                RatingButtons(hardDetail: "Again soon", easyDetail: "In 4 days", onHard: {}, onEasy: {})

                HStack(spacing: DS.Spacing.m) {
                    PlayButton(size: .large) {}
                    PlayButton(size: .medium, isPlaying: true) {}
                    PlayButton(size: .row) {}
                    PlayButton(size: .compact) {}
                    Button("Upgrade") {}
                        .buttonStyle(.primaryCompact)
                }

                HStack(spacing: DS.Spacing.xs) {
                    LevelLabel(language.phrases[0].level ?? "")
                    LevelLabel("Casual", style: .neutral)
                    LevelLabel(language.phrases[2].level ?? "", size: .compact)
                    Button("Word by word") {}
                        .buttonStyle(.inline)
                }
            }
            .padding(.vertical, DS.Spacing.s)
            .listRowBackground(DS.Color.ground)
        }
    }
}
