import Foundation
import Observation
import StoreKit

/// The paywall: loads the plans, buys the selected one, restores.
@MainActor
@Observable
final class PaywallModel {
    enum Phase: Equatable {
        case loading
        case ready
        case purchasing
        case purchased
        case failed(String)
    }

    private(set) var products: [Product] = []
    var selectedID: String = ProductID.yearly
    private(set) var phase: Phase = .loading

    @ObservationIgnored private let entitlements: any EntitlementService

    init(entitlements: any EntitlementService) {
        self.entitlements = entitlements
    }

    var selected: Product? {
        products.first { $0.id == selectedID }
    }

    func load() async {
        do {
            products = try await entitlements.products()
            if selected == nil, let first = products.first {
                selectedID = first.id
            }
            phase = products.isEmpty ? .failed("Plans couldn't be loaded. Check your connection and try again.") : .ready
        } catch {
            phase = .failed("Plans couldn't be loaded. Check your connection and try again.")
        }
    }

    /// - Returns: true when Pro is active afterwards.
    func purchase() async -> Bool {
        guard let product = selected else { return false }
        phase = .purchasing
        do {
            if try await entitlements.purchase(product) {
                phase = .purchased
                return true
            }
            phase = .ready
        } catch {
            phase = .failed("The purchase didn't go through. You haven't been charged.")
        }
        return false
    }

    func restore() async -> Bool {
        phase = .purchasing
        do {
            try await entitlements.restore()
        } catch {
            phase = .failed("Purchases couldn't be restored. Try again later.")
            return false
        }
        if entitlements.isPro {
            phase = .purchased
            return true
        }
        phase = .failed("No previous purchase was found for this Apple Account.")
        return false
    }

    /// "29,99 € per year", "2,99 € per month", "9,99 € once".
    static func priceLine(for product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else {
            return "\(product.displayPrice) once"
        }
        switch period.unit {
        case .year: return "\(product.displayPrice) per year"
        case .month: return "\(product.displayPrice) per month"
        case .week: return "\(product.displayPrice) per week"
        default: return product.displayPrice
        }
    }

    static func title(for product: Product) -> String {
        switch product.id {
        case ProductID.yearly: "Yearly"
        case ProductID.monthly: "Monthly"
        case ProductID.lifetime: "Lifetime"
        default: product.displayName
        }
    }
}
