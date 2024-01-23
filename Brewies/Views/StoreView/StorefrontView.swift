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
                
                ProductStoreView()
                    .environmentObject(storeKitManager)
            }
        }
    }
}


#Preview {
    StorefrontView()
}
