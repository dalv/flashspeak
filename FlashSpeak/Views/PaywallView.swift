import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = StoreManager.shared
    @ObservedObject private var usage = UsageManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.yellow)
                        
                        Text("Upgrade to Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Unlock unlimited translations")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Current usage
                    if !store.isSubscribed {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text("You've used \(usage.todayCount) of \(usage.dailyLimit) free translations today")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "infinity", text: "Unlimited translations")
                        FeatureRow(icon: "rectangle.stack.fill", text: "Unlimited flashcards")
                        FeatureRow(icon: "person.2.fill", text: "Formal & informal styles")
                        FeatureRow(icon: "bell.fill", text: "Daily practice reminders")
                        FeatureRow(icon: "heart.fill", text: "Support indie development")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Products
                    if store.isLoading {
                        ProgressView()
                            .padding()
                    } else if let error = store.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(store.products, id: \.id) { product in
                                ProductButton(product: product)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Restore purchases
                    Button("Restore Purchases") {
                        Task {
                            await store.restorePurchases()
                            if store.isSubscribed {
                                dismiss()
                            }
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    
                    // Terms
                    Text("Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in Settings.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 24)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

// MARK: - Product Button

struct ProductButton: View {
    let product: Product
    @ObservedObject private var store = StoreManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button {
            Task {
                let success = await store.purchase(product)
                if success {
                    dismiss()
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                    
                    if let subscription = product.subscription {
                        Text(subscriptionDescription(subscription))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.headline)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(store.isLoading)
    }
    
    private func subscriptionDescription(_ subscription: Product.SubscriptionInfo) -> String {
        switch subscription.subscriptionPeriod.unit {
        case .month:
            return "per month"
        case .year:
            return "per year"
        default:
            return ""
        }
    }
}

#Preview {
    PaywallView()
}
