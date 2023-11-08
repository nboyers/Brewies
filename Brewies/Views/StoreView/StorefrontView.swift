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
            ProductStoreView()
            
        }

    }
}

#Preview {
    StorefrontView()
}
