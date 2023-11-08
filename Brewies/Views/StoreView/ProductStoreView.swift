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
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("In-App Purchases")
                .bold()
            Divider()
            ForEach(storeKitManager.storeStatus.storeProducts.sorted(by: { $0.displayName < $1.displayName }).filter({ product in
                [StoreKitManager.adRemovalProductId, StoreKitManager.creditsProductId, StoreKitManager.favoritesSlotId].contains(product.id)
            })) { product in
                ProductItem(storeKit: storeKitManager, product: product)
            }
            Divider()
            HStack {
                Spacer()
                Button("Restore Purchases", action: {
                    Task {
                        try? await AppStore.sync()
                        await storeKitManager.checkIfAdsRemoved()
                    }
                })
                Spacer()
            }
        }
        .padding()
        .onReceive(storeKitManager.$storeStatus) { _ in
            // Action to be taken when store status changes.
        }
    }
}
struct ProductItem: View {
    @ObservedObject var storeKit: StoreKitManager
    var product: Product
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(product.displayName)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            Spacer()
            if storeKit.storeStatus.isAdRemovalPurchased && product.id == StoreKitManager.adRemovalProductId {
                Text("BOUGHT")
                    .foregroundColor(.gray)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.gray, lineWidth: 2)
                    )
            } else {
                Button(action: {
                    Task {
                        do {
                            _ = try await storeKit.purchase(product)
                        } catch {
                            // Handle errors if needed
                        }
                    }
                }) {
                    Text(product.displayPrice)
                        .padding(10)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(colorScheme == .dark ? .white : .black, lineWidth: 2)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview {
    ProductStoreView()
        .environmentObject(StoreKitManager())
}

