//
//  PaywallView.swift
//  Brewies
//

import SwiftUI
import StoreKit

/// The Brewies Pro paywall. StoreKit's subscription view supplies prices, trial terms,
/// the renewal disclosure, and restore, so the required legal text always matches the product.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    private let privacyURL = URL(string: "https://nobosoftware.com/privacy")!
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(productIDs: StoreManager.productIDs) {
                marketing
            }
            .subscriptionStoreControlStyle(.picker)
            .subscriptionStoreButtonLabel(.multiline)
            .subscriptionStorePolicyDestination(url: privacyURL, for: .privacyPolicy)
            .subscriptionStorePolicyDestination(url: termsURL, for: .termsOfService)
            .storeButton(.visible, for: .restorePurchases)
            .containerBackground(Theme.background, for: .subscriptionStore)
            .tint(Theme.accent)
            .onInAppPurchaseCompletion { _, result in
                if case .success(.success(_)) = result {
                    await store.refresh()
                    dismiss()
                }
            }
        }
    }

    private var marketing: some View {
        VStack(spacing: 22) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(Theme.accent)
                    CategoryIcon(category: .coffee, size: 30)
                        .foregroundStyle(.white)
                }
                .frame(width: 72, height: 72)

                Text("Brewies Pro")
                    .font(.display(.largeTitle, weight: .bold))
                Text("Keep every cup and pint you've logged, safe and everywhere.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 16) {
                feature("icloud.fill", "iCloud sync and backup", "Your journal follows you to every device and survives a lost phone.")
                feature("chart.bar.xaxis", "Insights", "Your top-rated shops, favorite orders, and how often you go.")
                feature("square.and.arrow.up", "Export your journal", "Take your visits with you as a spreadsheet any time.")
                feature("heart.fill", "Support an independent app", "Brewies is built by one person. Pro keeps it going.")
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func feature(_ systemImage: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
