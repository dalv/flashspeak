import SwiftUI

/// FlashSpeak Pro: shown when the free limit is reached, or from "Go Pro".
struct PaywallScreen: View {
    /// True when opened because the free limit was reached.
    var limitReached = false
    /// Called after a purchase or restore makes the user Pro.
    var onPurchased: () -> Void = {}

    @Environment(\.appDependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var model: PaywallModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.l) {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("FlashSpeak Pro")
                            .appTextStyle(.largeTitle)
                            .foregroundStyle(DS.Color.ink)
                        Text(limitReached
                            ? "You've used today's \(LocalUsageService.dailyTranslations) free translations. Your phrase is kept and translates as soon as you upgrade."
                            : "Translate as much as you like, in every language.")
                            .appTextStyle(.body)
                            .foregroundStyle(DS.Color.inkSecondary)
                    }

                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        PaywallBenefit("Unlimited translations")
                        PaywallBenefit("Unlimited suggested phrases and clarifications")
                        PaywallBenefit("All four languages, synced to your devices")
                    }

                    PaywallPlans(model: model)
                }
                .padding(.horizontal, DS.Spacing.screenPadding)
                .padding(.bottom, DS.Spacing.l)
            }
            .background(DS.Color.ground)
            .safeAreaBar(edge: .bottom) {
                VStack(spacing: DS.Spacing.s) {
                    PrimaryButton("Continue", isLoading: model?.phase == .purchasing, action: purchase)
                        .disabled(model?.selected == nil)
                    HStack(spacing: DS.Spacing.m) {
                        Button("Restore purchases", action: restore)
                        Button("Terms") { openURL(AppLinks.terms) }
                        if let privacy = AppLinks.privacy {
                            Button("Privacy") { openURL(privacy) }
                        }
                    }
                    .appTextStyle(.footnote)
                    .foregroundStyle(DS.Color.inkSecondary)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, DS.Spacing.screenPadding)
                .padding(.vertical, DS.Spacing.s)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                        .tint(DS.Color.ink)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .task {
            guard model == nil, let dependencies else { return }
            let model = PaywallModel(entitlements: dependencies.entitlements)
            self.model = model
            await model.load()
        }
    }

    private func purchase() {
        guard let model else { return }
        Task {
            if await model.purchase() {
                finish()
            }
        }
    }

    private func restore() {
        guard let model else { return }
        Task {
            if await model.restore() {
                finish()
            }
        }
    }

    private func finish() {
        dismiss()
        onPurchased()
    }
}

/// A check mark and one benefit.
private struct PaywallBenefit: View {
    let text: String

    @Environment(\.languageTheme) private var theme

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Label {
            Text(text)
                .appTextStyle(.callout)
                .foregroundStyle(DS.Color.ink)
        } icon: {
            Image(systemName: "checkmark")
                .appTextStyle(.footnote)
                .foregroundStyle(theme.accentText)
                .frame(width: DS.Size.minTouch - DS.Spacing.m, height: DS.Size.minTouch - DS.Spacing.m)
                .background(theme.accentTint, in: .circle)
        }
    }
}

/// The plan options, or loading and error states.
private struct PaywallPlans: View {
    let model: PaywallModel?

    var body: some View {
        if let model {
            VStack(spacing: DS.Spacing.s) {
                ForEach(model.products, id: \.id) { product in
                    PaywallPlanOption(
                        title: PaywallModel.title(for: product),
                        price: PaywallModel.priceLine(for: product),
                        badge: product.id == ProductID.yearly ? "Best value" : nil,
                        isSelected: model.selectedID == product.id
                    ) {
                        model.selectedID = product.id
                    }
                }
                if model.phase == .loading {
                    ProgressView("Loading plans…")
                        .appTextStyle(.secondary)
                }
                if case let .failed(message) = model.phase {
                    Text(message)
                        .appTextStyle(.secondary)
                        .foregroundStyle(DS.Color.danger)
                }
            }
        } else {
            ProgressView()
        }
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    Text("Home")
        .sheet(isPresented: .constant(true)) { PaywallScreen() }
        .dependencies(.preview())
        .languageTheme(.mandarin)
}

#Preview("Korean, dark", traits: .modifier(DesignSystemPreview())) {
    Text("Home")
        .sheet(isPresented: .constant(true)) { PaywallScreen() }
        .dependencies(.preview())
        .languageTheme(.korean)
        .preferredColorScheme(.dark)
}
