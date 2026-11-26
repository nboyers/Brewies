//
//  StoreManager.swift
//  Brewies
//
//  Tracks whether the user has an active Brewies Pro subscription.
//

import StoreKit
import Observation

@MainActor
@Observable
final class StoreManager {
    /// Product IDs in the Brewies Pro subscription group. Create these in App Store Connect.
    static let productIDs = [
        "com.nobosoftware.brewies.pro.yearly",
        "com.nobosoftware.brewies.pro.monthly"
    ]

    private static let cacheKey = "brewies.isPro"

    /// The last verified entitlement, so the right database opens at launch even when offline.
    static var cachedIsPro: Bool {
        UserDefaults.standard.bool(forKey: cacheKey)
    }

    private(set) var isPro: Bool

    private var updatesTask: Task<Void, Never>?

    init() {
        isPro = Self.cachedIsPro

        // Purchases, renewals, refunds and Ask to Buy approvals can arrive at any time.
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }

        Task { await refresh() }
    }

    /// Re-reads the user's current entitlements from the App Store.
    func refresh() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  Self.productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil else { continue }
            entitled = true
        }
        isPro = entitled
        UserDefaults.standard.set(entitled, forKey: Self.cacheKey)
    }

    /// Asks the App Store to sync purchases made on other devices.
    func restorePurchases() async {
        try? await AppStore.sync()
        await refresh()
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = result {
            await transaction.finish()
        }
        await refresh()
    }
}
