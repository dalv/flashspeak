import SwiftUI

/// Audio recall colours and type on the always-dark ground.
struct GalleryRecallSection: View {
    let language: SampleLanguage

    var body: some View {
        Section("Audio recall · always dark") {
            VStack(spacing: DS.Spacing.xl) {
                HStack {
                    GlassIconButton("End session", systemImage: "xmark") {}
                    Spacer()
                }

                VStack(spacing: DS.Spacing.s) {
                    Text("English")
                        .appTextStyle(.eyebrow)
                        .foregroundStyle(DS.Color.recallInkSecondary)
                    Text(language.phrases[0].english)
                        .appTextStyle(.recallPrompt)
                        .foregroundStyle(DS.Color.recallInk)
                    Text(language.phrases[0].native)
                        .nativeTextStyle(.recall, script: language.theme.script)
                        .foregroundStyle(language.theme.accentOnDark)
                }
                .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    ProgressView(value: 0.6)
                        .tint(language.theme.accentOnDark)
                    Text("12 of 20 this session")
                        .appTextStyle(.footnote)
                        .foregroundStyle(DS.Color.recallInkSecondary)
                }
            }
            .padding(DS.Spacing.recallScreenPadding)
            .frame(maxWidth: .infinity)
            .background(DS.Color.recallGround, in: .rect(cornerRadius: DS.Radius.card))
            .environment(\.colorScheme, .dark)
            .listRowBackground(DS.Color.ground)
            .listRowInsets(EdgeInsets())
        }
    }
}
