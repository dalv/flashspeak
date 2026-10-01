import SwiftUI

/// Preview setup for design-system views: registers the Noto fonts once
/// and puts the view on the app's `ground`.
///
/// Use as `#Preview(traits: .modifier(DesignSystemPreview()))`.
struct DesignSystemPreview: PreviewModifier {
    static func makeSharedContext() async throws {
        FontRegistration.registerBundledFonts()
    }

    func body(content: Content, context _: Void) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DS.Color.ground)
    }
}
