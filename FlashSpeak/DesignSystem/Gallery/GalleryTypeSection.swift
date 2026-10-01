import SwiftUI

/// The UI type ramp, the native ramp in the selected language, and the
/// hero size in all four scripts.
struct GalleryTypeSection: View {
    let language: SampleLanguage

    var body: some View {
        Section("Type · SF Pro") {
            ForEach(AppTextStyle.allCases, id: \.self) { style in
                Text(style.name)
                    .appTextStyle(style)
                    .foregroundStyle(DS.Color.ink)
            }
        }
        .dsListRows()

        Section("Type · \(language.theme.displayName)") {
            ForEach(NativeTextStyle.allCases, id: \.self) { style in
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text(style == .reading ? (language.phrases[0].reading ?? language.phrases[0].native) : language.phrases[0].native)
                        .nativeTextStyle(style, script: language.theme.script)
                        .foregroundStyle(DS.Color.ink)
                    Text(style.name)
                        .appTextStyle(.caption)
                        .foregroundStyle(DS.Color.inkSecondary)
                }
            }
        }
        .dsListRows()
        .id(ComponentGallery.SectionID.nativeType)

        Section("Native scripts side by side") {
            ForEach(SampleContent.languages) { sample in
                Text(sample.phrases[1].native)
                    .nativeTextStyle(.hero, script: sample.theme.script)
                    .foregroundStyle(DS.Color.ink)
            }
            // Same Han characters, regional glyph forms: 骨 直 角 説.
            HStack(spacing: DS.Spacing.l) {
                Text("骨直角说")
                    .nativeTextStyle(.hero, script: .simplifiedChinese)
                Text("骨直角説")
                    .nativeTextStyle(.hero, script: .japanese)
            }
            .foregroundStyle(DS.Color.ink)
        }
        .dsListRows()
        .id(ComponentGallery.SectionID.scripts)
    }
}
