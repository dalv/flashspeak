import Foundation
import StoreKit

class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    // Product IDs - you'll configure these in App Store Connect
    static let monthlyProductID = "com.flashspeak.pro.monthly"
    static let yearlyProductID = "com.flashspeak.pro.yearly"
    static let lifetimeProductID = "com.flashspeak.pro.lifetime"
    
    @Published var products: [Product] = []
    #if DEBUG
    @Published var isSubscribed: Bool = true
    #else
    @Published var isSubscribed: Bool = false
    #endif
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    @MainActor
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let productIDs = [
                Self.monthlyProductID,
                Self.yearlyProductID,
                Self.lifetimeProductID
            ]
            
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase
    
    @MainActor
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
                isLoading = false
                return true
                
            case .userCancelled:
                isLoading = false
                return false
                
            case .pending:
                errorMessage = "Purchase is pending approval"
                isLoading = false
                return false
                
            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("Purchase failed: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    @MainActor
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Subscription Status
    
    @MainActor
    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false
        
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    hasActiveSubscription = true
                    break
                }
            }
        }
        
        #if DEBUG
        isSubscribed = true
        #else
        isSubscribed = hasActiveSubscription
        #endif
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                }
            }
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    enum StoreError: Error {
        case failedVerification
    }
}
