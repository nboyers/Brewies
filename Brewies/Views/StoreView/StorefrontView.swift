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


struct StorefrontView_Previews: PreviewProvider {
    static var previews: some View {
        StorefrontView()
    }
}
