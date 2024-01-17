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
        GeometryReader { geometry in
            VStack(spacing: 0) {
                SubscriptionView()
                    .environmentObject(storeKitManager)
                    .frame(height: geometry.size.height / 2) // Half the height of the screen
                
                ProductStoreView()
                    .environmentObject(storeKitManager)
                    .frame(height: geometry.size.height / 2) // Half the height of the screen
            }
        }
        .onAppear {
            storeKitManager.refreshData()
        }
    }
}


#Preview {
    StorefrontView()
}
