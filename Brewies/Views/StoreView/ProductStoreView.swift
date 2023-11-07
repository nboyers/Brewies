//
//  ProductStoreView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/5/23.
//

import SwiftUI
import StoreKit

struct ProductStoreView: View {
    @StateObject var storeKit = StoreKitManager()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("In-App Purchases")
                .bold()
            Divider()
            ForEach(storeKit.storeProducts.sorted(by: { $0.displayName < $1.displayName })) { product in
                HStack {
                    Text(product.displayName)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Spacer()
                    Button(action: {
                        // purchase this product
                        Task {
                            try await storeKit.purchase(product)
                        }
                    }) {
                        CourseItem(storeKit: storeKit, product: product)
                    }
                }
            }
            Divider()
            HStack {
                Spacer()
                Button("Restore Purchases", action: {
                    Task {
                        try? await AppStore.sync()
                        await storeKit.checkIfAdsRemoved()
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
    
    // We use this to get access to the colorScheme to set the color conditionally
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if storeKit.isAdRemovalPurchased && product.id == storeKit.adRemovalProductId {
                // If ad removal is purchased and this product is the ad removal product
                // Then show "BOUGHT" and gray it out.
                Text("BOUGHT")
                    .foregroundColor(.gray)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.gray, lineWidth: 2)
                            .disabled(true)
                    )
            } else {
                // Otherwise, show the price and allow interaction.
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
                // Disable button if the product is already purchased
                .disabled(isPurchased)
                .onReceive(storeKit.$purchasedCourses) { _ in
                    // Update isPurchased when purchasedCourses changes
                    isPurchased = storeKit.purchasedCourses.contains(where: { $0.id == product.id })
                }
            }
        }
        
        .onChange(of: storeKit.isAdRemovalPurchased) { _ in
            // If the ad removal purchase status changes, update isPurchased
            isPurchased = storeKit.isAdRemovalPurchased && product.id == storeKit.adRemovalProductId
        }
    }
}

#Preview {
    ProductStoreView()
        .environmentObject(StoreKitManager())
}

