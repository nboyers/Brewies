//
//  StorefrontView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/6/23.
//

import SwiftUI

struct StorefrontView: View {
    @StateObject var storeKit = StoreKitManager()
    
    var body: some View {
        VStack {
            SubscriptionView()
            ProductStoreView()
        }
        .onAppear {
            Task {
                await storeKit.requestProducts()
                await storeKit.updateCustomerProductStatus()
            }
        }
        .environmentObject(storeKit)
    }
}


#Preview {
    StorefrontView(storeKit: StoreKitManager())
}
