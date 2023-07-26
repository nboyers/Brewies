//
//  FavoriteView.swift
//  Brewies
//
//  Created by Noah Boyers on 5/12/23.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var coffeeShopData = CoffeeShopData.shared
    @ObservedObject var storeKit = StoreKitManager()
    
    @Binding var showPreview: Bool
   
    @EnvironmentObject var userVM: UserViewModel

    @State private var showRemovalConfirmationAlert = false
    @State private var toRemoveCoffeeShop: CoffeeShop?

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(coffeeShopData.favoriteShops, id: \.id) { coffeeShop in
                        NavigationLink(destination: BrewDetailView(coffeeShop: coffeeShop)) {
                            VStack {
                                BrewPreview(coffeeShop: coffeeShop, showBrewPreview: $showPreview)
                                if !storeKit.isAdRemovalPurchased && !userVM.user.isSubscribed {
                                    AdBannerView()
                                        .frame(width: 320, height: 50)
                                }
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                toRemoveCoffeeShop = coffeeShop
                                showRemovalConfirmationAlert = true
                            }) {
                                Text("Remove from favorites")
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
                .padding(.all, 16)
            }
            .navigationTitle("Favorites")
            .alert(isPresented: $showRemovalConfirmationAlert) {
                Alert(title: Text("Remove from favorites"),
                      message: Text("Are you sure you want to remove this coffee shop from your favorites?"),
                      primaryButton: .destructive(Text("Remove")) {
                        if let toRemove = toRemoveCoffeeShop {
                            coffeeShopData.removeFromFavorites(toRemove)
                        }
                      },
                      secondaryButton: .cancel())
            }
        }
    }
}
