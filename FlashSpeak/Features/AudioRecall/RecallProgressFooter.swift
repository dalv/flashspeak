import SwiftUI

/// Progress through the session and the hold/swipe hint.
struct RecallProgressFooter: View {
    let position: Int
    let total: Int
    let setCount: Int

    @Environment(\.languageTheme) private var theme

    var body: some View {
        VStack(spacing: DS.Spacing.s) {
            ProgressView(value: Double(position), total: Double(max(total, 1)))
                .progressViewStyle(.linear)
                .tint(theme.accentOnDark)
            HStack {
                Text("\(Text("\(position)").foregroundStyle(DS.Color.recallInk).bold()) of \(total) this session")
                Spacer()
                Text("\(setCount) in set")
            }
            .appTextStyle(.footnote)
            .foregroundStyle(DS.Color.recallInkSecondary)
            Text("Hold anywhere to pause · swipe to skip")
                .appTextStyle(.footnote)
                .foregroundStyle(DS.Color.recallInkSecondary)
                .padding(.top, DS.Spacing.xxs)
        }
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    VStack(spacing: DS.Spacing.l) {
        ForEach(LanguageTheme.all) { theme in
            RecallProgressFooter(position: 12, total: 20, setCount: 148).languageTheme(theme)
        }
    }
    .padding()
    .background(DS.Color.recallGround)
}
