import SwiftUI

/// A round Liquid Glass button with an SF Symbol, for places outside a
/// navigation toolbar (toolbar items get glass automatically).
///
/// The title is always given, so VoiceOver reads it even though only the
/// icon shows.
struct GlassIconButton: View {
    private let title: LocalizedStringKey
    private let systemImage: String
    private let isAccented: Bool
    private let action: () -> Void

    @Environment(\.languageTheme) private var theme

    init(
        _ title: LocalizedStringKey,
        systemImage: String,
        isAccented: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isAccented = isAccented
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .appTextStyle(.headline)
                .foregroundStyle(isAccented ? theme.accentText : DS.Color.ink)
                .frame(width: DS.Size.minTouch, height: DS.Size.minTouch)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack(spacing: DS.Spacing.l) {
        ForEach(LanguageTheme.all) { theme in
            HStack(spacing: DS.Spacing.s) {
                GlassIconButton("Back", systemImage: "chevron.left") {}
                GlassIconButton("Close", systemImage: "xmark") {}
                GlassIconButton("Report a bad translation", systemImage: "flag") {}
                GlassIconButton("Pause", systemImage: "pause.fill", isAccented: true) {}
            }
            .languageTheme(theme)
        }
    }
}
