//
//  ProductStoreView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/5/23.
//

import SwiftUI
import StoreKit

struct ProductStoreView: View {
    @EnvironmentObject var storeKitManager: StoreKitManager // Use the shared instance provided by the environment.
    @Environment(\.colorScheme) var colorScheme
    
    private var filteredProducts: [Product] {
        storeKitManager.storeStatus.storeProducts
            .sorted(by: { $0.displayName < $1.displayName })
            .filter { product in
                [StoreKitManager.adRemovalProductId, StoreKitManager.creditsProductId, StoreKitManager.favoritesSlotId].contains(product.id)
            }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            headerView
            productsListView
            restorePurchasesButton
        }
        .padding()
        .onReceive(storeKitManager.$storeStatus) { _ in
            // Action to be taken when store status changes.
        }
    }
    
    private var headerView: some View {
        Text("In-App Purchases")
            .bold()
    }
    
    private var productsListView: some View {
        ForEach(filteredProducts) { product in
            ProductItem(storeKit: storeKitManager, product: product)
        }
    }
    
    private var restorePurchasesButton: some View {
        return HStack {
            Spacer()
            Button("Restore Purchases") {
                Task {
                    try? await AppStore.sync()
                    await storeKitManager.checkIfAdsRemoved()
                }
            }
            Spacer()
        }
    }
}

struct ProductItem: View {
    @ObservedObject var storeKit: StoreKitManager
    var product: Product
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            productTitle
            Spacer()
            purchaseOrBoughtView
        }
    }
    
    private var productTitle: some View {
        Text(product.displayName)
            .foregroundColor(colorScheme == .dark ? .white : .black)
    }
    
    private var purchaseOrBoughtView: some View {
        Group {
            if storeKit.storeStatus.isAdRemovalPurchased && product.id == StoreKitManager.adRemovalProductId {
                purchasedLabel
            } else {
                purchaseButton
            }
        }
    }
    
    private var purchasedLabel: some View {
        Text("BOUGHT")
            .foregroundColor(.gray)
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.gray, lineWidth: 2)
            )
    }
    
    private var purchaseButton: some View {
        Button(action: purchaseAction) {
            Text(product.displayPrice)
                .padding(5)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(colorScheme == .dark ? .white : .black, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func purchaseAction() {
        Task {
            do {
                _ = try await storeKit.purchase(product)
            } catch {
                // Handle errors if needed
            }
        }
    }
}

struct ProductStoreView_Previews: PreviewProvider {
    static var previews: some View {
        ProductStoreView().environmentObject(StoreKitManager())
    }
}
