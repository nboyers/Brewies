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
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("In-App Purchase")
                .bold()
            Divider()
            ForEach(storeKit.storeProducts) { product in
                HStack {
                    Text(product.displayName)
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
    @ObservedObject var storeKit : StoreKitManager
    @State var isPurchased: Bool = false
    var product: Product
    
    var body: some View {
        VStack {
            if isPurchased {
                Text(Image(systemName: "checkmark"))
                    .bold()
                    .padding(10)
            } else {
                Text(product.displayPrice)
                    .padding(10)
            }
        }
        .onChange(of: storeKit.isAdRemovalPurchased) { value in
            isPurchased = value
        }
        .onChange(of: storeKit.purchasedCourses) { course in
            Task {
                isPurchased = (try? await storeKit.isPurchased(product)) ?? false
            }
        }
    }
}


struct ProductStoreView_Previews: PreviewProvider {
    static var previews: some View {
        ProductStoreView().environmentObject(StoreKitManager())
    }
}
