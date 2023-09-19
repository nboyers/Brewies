//
//  FavoriteView.swift
//  Brewies
//
//  Created by Noah Boyers on 5/12/23.
//

import SwiftUI


struct FavoritesView: View {
    @EnvironmentObject var contentVM: ContentViewModel
    @EnvironmentObject var userVM: UserViewModel
    
    @ObservedObject var coffeeShopData = CoffeeShopData.shared
    @ObservedObject var storeKit = StoreKitManager()
    
    @Binding var showPreview: Bool
    
    @State private var showRemovalConfirmationAlert = false
    @State private var toRemoveCoffeeShop: CoffeeShop?
    
    @Binding var activeSheet: ActiveSheet?

    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack {
                        Text("Ads Watched: \(contentVM.adsWatched)/3")
                        
                        ProgressView(value: Float(contentVM.adsWatched), total: 5)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Button("Watch Ad to Unlock Favorite Slot") {
                            contentVM.handleRewardAd(reward: "favorites")
                        }
                    }
                    
                    ForEach(coffeeShopData.favoriteShops.prefix(coffeeShopData.maxFavoriteSlots), id: \.id) { coffeeShop in
                        
                        NavigationLink(destination: BrewDetailView(coffeeShop: coffeeShop)) {
                            VStack {
                                BrewPreview(coffeeShop: coffeeShop, activeSheet: $activeSheet, showBrewPreview: $showPreview)

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
                    if !storeKit.isAdRemovalPurchased && !userVM.user.isSubscribed {
                        AdBannerView()
                            .frame(width: 320, height: 50)
                    }
                }
                .padding(.all, 16)
                .onChange(of: contentVM.adsWatched) { newValue in
                    if newValue >= 3 {
                        coffeeShopData.maxFavoriteSlots += 1  // Update the maxFavoriteSlots
                    }
                }
                
            }
            .navigationTitle("Favorites - \(coffeeShopData.favoriteShops.count)/\(coffeeShopData.maxFavoriteSlots) slots")
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
