//
//  ProductStoreView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/5/23.
//

import SwiftUI
import StoreKit

struct ProductStoreView: View {
//    @StateObject var storeKitManager = StoreKitManager()
    @EnvironmentObject var storeKitManager: StoreKitManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("In-App Purchases")
                .bold()
            Divider()
            // Filtering out subscription products based on their ID
            ForEach(storeKitManager.storeStatus.storeProducts.sorted(by: { $0.displayName < $1.displayName }).filter({ product in
                // Assuming 'adRemovalProductId', 'creditsProductId', and 'favoritesSlotId' are non-subscription products
                [StoreKitManager.adRemovalProductId, StoreKitManager.creditsProductId, StoreKitManager.favoritesSlotId].contains(product.id)
            })) { product in
                HStack {
                    Text(product.displayName)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Spacer()
                    Button(action: {
                        // Purchase this product
                        Task {
                            do {
                                _ = try await storeKitManager.purchase(product)
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
                    .buttonStyle(PlainButtonStyle()) // To remove default button styling
                }
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
    }
}

struct CourseItem: View {
    @ObservedObject var storeKit: StoreKitManager
    @State var isPurchased: Bool = false
    var product: Product
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
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
                    // Purchase this product
                    Task {
                        try await storeKit.purchase(product)
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
                .disabled(isPurchased)
            }
        }
        .onChange(of: storeKit.storeStatus.isAdRemovalPurchased) { _ in
            isPurchased = storeKit.storeStatus.isAdRemovalPurchased && product.id == StoreKitManager.adRemovalProductId
        }
    }
}


#Preview {
    ProductStoreView()
        .environmentObject(StoreKitManager())
}

