import Foundation
import Observation
import StoreKit

/// `EntitlementService` on StoreKit 2.
///
/// DEBUG builds are Pro unless launched with `-forceFree`, so the paywall
/// and free limit can be tested (CLAUDE.md).
@MainActor
@Observable
final class StoreKitEntitlementService: EntitlementService {
    private(set) var hasActiveEntitlement = false

    var isPro: Bool {
        #if DEBUG
            return !CommandLine.arguments.contains("-forceFree") || hasActiveEntitlement
        #else
            return hasActiveEntitlement
        #endif
    }

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case let .verified(transaction) = update {
                    await transaction.finish()
                }
                await self?.refresh()
            }
        }
        Task { await refresh() }
    }

    func products() async throws -> [Product] {
        try await Product.products(for: ProductID.all)
            .sorted { ProductID.all.firstIndex(of: $0.id) ?? 0 < ProductID.all.firstIndex(of: $1.id) ?? 0 }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        guard case let .success(verification) = result, case let .verified(transaction) = verification else {
            return false
        }
        await transaction.finish()
        await refresh()
        return hasActiveEntitlement
    }

    func restore() async throws {
        try await AppStore.sync()
        await refresh()
    }

    private func refresh() async {
        var active = false
        for await entitlement in Transaction.currentEntitlements {
            // Any valid purchase counts, so subscribers on older product IDs keep Pro.
            if case let .verified(transaction) = entitlement, transaction.revocationDate == nil {
                active = true
            }
        }
        hasActiveEntitlement = active
    }
}
