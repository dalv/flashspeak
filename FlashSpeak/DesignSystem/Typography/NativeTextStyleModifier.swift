import SwiftUI

/// Applies a `NativeTextStyle` in the script's font, scaled with Dynamic Type.
struct NativeTextStyleModifier: ViewModifier {
    private let style: NativeTextStyle
    private let script: NativeScript
    @ScaledMetric private var systemSize: CGFloat

    init(_ style: NativeTextStyle, script: NativeScript) {
        self.style = style
        self.script = script
        _systemSize = ScaledMetric(wrappedValue: style.size, relativeTo: style.relativeTo)
    }

    func body(content: Content) -> some View {
        content
            .font(font)
            .typesettingLanguage(script.language)
    }

    private var font: Font {
        style.customFont(for: script)
            ?? .system(size: systemSize, weight: style.isBold ? .bold : .regular)
    }
}

extension View {
    func nativeTextStyle(_ style: NativeTextStyle, script: NativeScript) -> some View {
        modifier(NativeTextStyleModifier(style, script: script))
    }
}
