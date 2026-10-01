import SwiftUI

/// Applies an `AppTextStyle`, scaling its design size with Dynamic Type.
struct AppTextStyleModifier: ViewModifier {
    private let style: AppTextStyle
    @ScaledMetric private var size: CGFloat

    init(_ style: AppTextStyle) {
        self.style = style
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: style.relativeTo)
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: style.weight))
            .tracking(style.tracking)
            .textCase(style.isUppercase ? .uppercase : nil)
    }
}

extension View {
    func appTextStyle(_ style: AppTextStyle) -> some View {
        modifier(AppTextStyleModifier(style))
    }
}
