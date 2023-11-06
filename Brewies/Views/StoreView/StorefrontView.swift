//
//  StorefrontView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/6/23.
//

import SwiftUI

struct StorefrontView: View {
    @StateObject var storeVM = StoreKitManager()
    
    var body: some View {
        VStack {
            SubscriptionView()
            ProductStoreView()
        }
        .environmentObject(storeVM)
    }
}


#Preview {
    StorefrontView(storeVM: StoreKitManager())
}
