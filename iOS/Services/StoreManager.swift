import Foundation
import StoreKit

/// StoreKit 2 subscription handling: Premium Monthly and Premium Yearly,
/// each with a 7-day free trial configured as an Introductory Offer in App Store Connect.
@MainActor
final class StoreManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium = false
    @Published private(set) var isInTrial = false
    @Published private(set) var isLoading = false

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
                await self?.refreshEntitlements()
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit { updatesTask?.cancel() }

    var yearly: Product? { products.first { $0.id == AppConfig.yearlyProductID } }
    var monthly: Product? { products.first { $0.id == AppConfig.monthlyProductID } }
    var lifetime: Product? { products.first { $0.id == AppConfig.lifetimeProductID } }

    func loadProducts() async {
        guard products.isEmpty, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await Product.products(for: AppConfig.allProductIDs)
            let order = AppConfig.allProductIDs
            products = fetched.sorted { (order.firstIndex(of: $0.id) ?? 9) < (order.firstIndex(of: $1.id) ?? 9) }
        } catch {
            print("Lumina: failed to load products – \(error)")
        }
    }

    /// Returns true when the purchase (or trial start) completed.
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlements()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var active = false
        var trial = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result,
                  AppConfig.allProductIDs.contains(t.productID),
                  t.revocationDate == nil else { continue }
            if let expiry = t.expirationDate, expiry < .now { continue }
            active = true
            if t.offerType == .introductory { trial = true }
        }
        isPremium = active
        isInTrial = trial
    }

    func isTrialEligible(for product: Product?) async -> Bool {
        guard let sub = product?.subscription, sub.introductoryOffer != nil else { return false }
        return await sub.isEligibleForIntroOffer
    }

    /// Percentage saved by choosing yearly over 12 months of monthly.
    var yearlySavingsPercent: Int? {
        guard let y = yearly, let m = monthly, m.price > 0 else { return nil }
        let yearlyValue = NSDecimalNumber(decimal: y.price).doubleValue
        let monthlyValue = NSDecimalNumber(decimal: m.price).doubleValue * 12
        guard monthlyValue > yearlyValue else { return nil }
        return Int(((1 - yearlyValue / monthlyValue) * 100).rounded())
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified: throw StoreError.failedVerification
        }
    }
}

enum StoreError: LocalizedError {
    case failedVerification
    var errorDescription: String? { "We couldn't verify this purchase with the App Store. Please try again." }
}

extension Product {
    var isLifetime: Bool { id == AppConfig.lifetimeProductID }

    var periodWord: String {
        if isLifetime { return "once" }
        guard let period = subscription?.subscriptionPeriod else { return "" }
        switch period.unit {
        case .year: return "year"
        case .month: return "month"
        case .week: return "week"
        case .day: return "day"
        @unknown default: return "period"
        }
    }

    var monthlyEquivalent: String? {
        guard subscription?.subscriptionPeriod.unit == .year else { return nil }
        return (price / 12).formatted(priceFormatStyle)
    }
}
