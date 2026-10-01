import SwiftUI

/// Every token and component on one screen, for design review.
///
/// The language picker at the top switches the theme for the whole
/// gallery. In DEBUG builds, launch with `-componentGallery` to show it
/// instead of the app; add `-gallerySection buttons` to scroll to a
/// section and `-galleryLanguage ko` to pick a language (for screenshots).
struct ComponentGallery: View {
    enum SectionID: String, CaseIterable {
        case colour, type, nativeType, scripts, shape, buttons, segments, card, rows, settings, recall
    }

    @State private var theme = LanguageTheme.forCode(
        UserDefaults.standard.string(forKey: "galleryLanguage") ?? ""
    ) ?? .mandarin

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    GalleryColorsSection().id(SectionID.colour)
                    GalleryTypeSection(language: language).id(SectionID.type)
                    GalleryShapeSection().id(SectionID.shape)
                    GalleryButtonsSection(language: language).id(SectionID.buttons)
                    GallerySegmentsSection().id(SectionID.segments)
                    GalleryPhraseCardSection(language: language).id(SectionID.card)
                    GalleryPhraseRowSection(language: language).id(SectionID.rows)
                    GallerySettingsSection().id(SectionID.settings)
                    GalleryRecallSection(language: language).id(SectionID.recall)
                }
                .dsGroupedList()
                .onAppear {
                    scrollToRequestedSection(proxy)
                }
            }
            .navigationTitle("Design system")
            .navigationDestination(for: String.self) { Text($0) }
            .safeAreaInset(edge: .top) {
                SegmentedControl(selection: $theme, options: LanguageTheme.all, variant: .glassAccent) { theme in
                    Text(theme.nativeName)
                        .nativeTextStyle(.segment, script: theme.script)
                }
                .padding(.horizontal, DS.Spacing.screenPadding)
                .padding(.bottom, DS.Spacing.xs)
            }
        }
        .languageTheme(theme)
    }

    private var language: SampleLanguage {
        SampleContent.language(for: theme)
    }

    private func scrollToRequestedSection(_ proxy: ScrollViewProxy) {
        guard let raw = UserDefaults.standard.string(forKey: "gallerySection"),
              let section = SectionID(rawValue: raw) else { return }
        proxy.scrollTo(section, anchor: .top)
    }
}

#Preview("Light", traits: .modifier(DesignSystemPreview())) {
    ComponentGallery()
}

#Preview("Dark", traits: .modifier(DesignSystemPreview())) {
    ComponentGallery()
        .preferredColorScheme(.dark)
}

#Preview("Accessibility text", traits: .modifier(DesignSystemPreview())) {
    ComponentGallery()
        .dynamicTypeSize(.accessibility2)
}
