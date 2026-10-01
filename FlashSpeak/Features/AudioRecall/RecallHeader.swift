import SwiftUI

/// End session, the title and language, and the session speed.
struct RecallHeader: View {
    let speed: PlaybackSpeed
    let onClose: () -> Void

    @Environment(\.languageTheme) private var theme

    var body: some View {
        HStack {
            GlassIconButton("End session", systemImage: "xmark", action: onClose)
            Spacer()
            VStack(spacing: 0) {
                Text("Audio recall")
                    .appTextStyle(.subheadlineEmphasized)
                    .foregroundStyle(DS.Color.recallInk)
                Text(theme.displayName)
                    .appTextStyle(.footnote)
                    .foregroundStyle(DS.Color.recallInkSecondary)
            }
            Spacer()
            Text(speed.title)
                .appTextStyle(.captionEmphasized)
                .foregroundStyle(DS.Color.recallInk)
                .padding(.horizontal, DS.Spacing.s)
                .frame(minHeight: DS.Size.compactButtonHeight)
                .background(DS.Color.recallTrack, in: .capsule)
        }
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack(spacing: DS.Spacing.l) {
        ForEach(LanguageTheme.all) { theme in
            RecallHeader(speed: .slow, onClose: {}).languageTheme(theme)
        }
    }
    .padding()
    .background(DS.Color.recallGround)
    .environment(\.colorScheme, .dark)
}
