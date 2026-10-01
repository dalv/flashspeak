import Observation
import StoreKit

/// An `EntitlementService` for Previews and tests, with no products.
@MainActor
@Observable
final class FakeEntitlementService: EntitlementService {
    var isPro: Bool

    init(isPro: Bool = false) {
        self.isPro = isPro
    }

    func products() async throws -> [Product] {
        []
    }

    func purchase(_: Product) async throws -> Bool {
        isPro = true
        return true
    }

    func restore() async throws {}

    #if DEBUG
        var debugForceFree: Bool {
            get { !isPro }
            set { isPro = !newValue }
        }
    #endif
}
