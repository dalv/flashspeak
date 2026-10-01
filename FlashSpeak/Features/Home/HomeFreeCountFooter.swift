import SwiftUI

/// "2 of 3 free translations left today · Go Pro", for free users only.
struct HomeFreeCountFooter: View {
    /// Nil for Pro: nothing is shown.
    let remaining: Int?

    @Environment(\.languageTheme) private var theme
    @State private var showsPaywall = false

    var body: some View {
        if let remaining {
            Button {
                showsPaywall = true
            } label: {
                Text("\(remaining) of \(LocalUsageService.dailyTranslations) free translations left today · \(Text("Go Pro").foregroundStyle(theme.accentText).bold())")
                    .appTextStyle(.secondary)
                    .foregroundStyle(DS.Color.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.screenPadding)
                    .padding(.vertical, DS.Spacing.s)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows FlashSpeak Pro")
            .sheet(isPresented: $showsPaywall) {
                PaywallScreen()
            }
        }
    }
}
