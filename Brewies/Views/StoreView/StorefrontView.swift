//
//  StorefrontView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/6/23.
//

import SwiftUI

struct StorefrontView: View {
    @StateObject var storeKitManager = StoreKitManager()
    
    var body: some View {
        VStack {
            SubscriptionView()
                .environmentObject(storeKitManager) // Pass the environment object to the SubscriptionView
            ProductStoreView()
                .environmentObject(storeKitManager) // Pass the environment object to the ProductStoreView
        }
        .onAppear {
           storeKitManager.refreshData()

        }
    }
}

#Preview {
    StorefrontView()
}
