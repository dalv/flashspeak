import SwiftUI

/// A segmented control in the app's style.
///
/// The label builder lets each option use its own font, so the language
/// picker shows 中文, 한국어 and 日本語 in their scripts. Each segment is a
/// button with the selected trait for VoiceOver.
struct SegmentedControl<Option: Hashable, Label: View>: View {
    @Binding private var selection: Option
    private let options: [Option]
    private let variant: SegmentedControlVariant
    private let label: (Option) -> Label

    @Environment(\.languageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var thumb

    init(
        selection: Binding<Option>,
        options: [Option],
        variant: SegmentedControlVariant,
        @ViewBuilder label: @escaping (Option) -> Label
    ) {
        _selection = selection
        self.options = options
        self.variant = variant
        self.label = label
    }

    var body: some View {
        HStack(spacing: variant == .inline ? DS.Spacing.xxs / 2 : DS.Spacing.xxs) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    select(option)
                } label: {
                    label(option)
                        .appTextStyle(textStyle(isSelected: isSelected))
                        .lineLimit(1)
                        .minimumScaleFactor(variant == .inline ? 0.7 : 0.8)
                        .foregroundStyle(foreground(isSelected: isSelected))
                        .padding(.horizontal, variant == .inline ? DS.Spacing.xxs : DS.Spacing.xs)
                        .frame(maxWidth: .infinity, minHeight: segmentHeight)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(thumbFill)
                                    .shadow(variant == .glassAccent ? .none : .thumb)
                                    .matchedGeometryEffect(id: "thumb", in: thumb)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityShowsLargeContentViewer()
            }
        }
        .padding(variant == .inline ? DS.Spacing.xxs - 1 : DS.Spacing.xxs)
        .background {
            if variant == .inline {
                Capsule().fill(DS.Color.ground)
            }
        }
        .glassEffect(variant == .inline ? .identity : .regular, in: .capsule)
        .accessibilityElement(children: .contain)
        // Like the system segmented control: cap the size and rely on the
        // large content viewer at accessibility sizes.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private var segmentHeight: CGFloat {
        variant == .inline ? DS.Size.inlineSegmentHeight : DS.Size.segmentHeight
    }

    private func textStyle(isSelected: Bool) -> AppTextStyle {
        if variant == .inline {
            return isSelected ? .secondaryEmphasized : .secondary
        }
        return isSelected ? .subheadlineEmphasized : .subheadline
    }

    private var thumbFill: Color {
        variant == .glassAccent ? theme.accent : DS.Color.surface
    }

    private func foreground(isSelected: Bool) -> Color {
        switch (variant, isSelected) {
        case (.glassAccent, true): DS.Color.onAccent
        case (.glassAccent, false): DS.Color.ink
        case (_, true): DS.Color.ink
        case (_, false): DS.Color.inkSecondary
        }
    }

    private func select(_ option: Option) {
        withAnimation(reduceMotion ? nil : .snappy) {
            selection = option
        }
    }
}

private extension DS.Shadow {
    static let none = DS.Shadow(color: .clear, radius: 0, y: 0)
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    @Previewable @State var language = LanguageTheme.mandarin
    @Previewable @State var mode = "Speak"
    @Previewable @State var speed = "Slow"

    VStack(spacing: DS.Spacing.l) {
        SegmentedControl(selection: $language, options: LanguageTheme.all, variant: .glassAccent) { theme in
            Text(theme.nativeName)
                .nativeTextStyle(.segment, script: theme.script)
        }
        SegmentedControl(selection: $mode, options: ["Speak", "Type", "Suggest"], variant: .glass) {
            Text($0)
        }
        SegmentedControl(selection: $speed, options: ["Natural", "Slow", "Word by word"], variant: .inline) {
            Text($0)
        }
        .padding(DS.Spacing.cardPadding)
        .background(DS.Color.surface, in: .rect(cornerRadius: DS.Radius.card))
    }
    .padding(DS.Spacing.screenPadding)
    .languageTheme(language)
}
