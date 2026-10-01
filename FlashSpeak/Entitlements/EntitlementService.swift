import StoreKit

/// Pro status and purchases. Observable.
@MainActor
protocol EntitlementService: AnyObject {
    var isPro: Bool { get }
    func products() async throws -> [Product]
    /// - Returns: true if the purchase completed and Pro is now active.
    func purchase(_ product: Product) async throws -> Bool
    func restore() async throws

    #if DEBUG
        /// DEBUG only: act as a free user, to test the paywall and limits.
        var debugForceFree: Bool { get set }
    #endif
}

/// The App Store products. These are the 1.0 app's IDs (also in
/// Products.storekit); the legacy `com.flashspeak.pro.*` IDs in StoreManager
/// don't match App Store Connect (current-state.md).
enum ProductID {
    static let monthly = "com.flashspeak.chinese.monthly"
    static let yearly = "com.flashspeak.chinese.yearly29"
    static let lifetime = "com.flashspeak.chinese.lifetime"
    /// Paywall order: yearly first (selected by default).
    static let all = [yearly, monthly, lifetime]
}
