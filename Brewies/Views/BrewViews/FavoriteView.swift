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
    
    @State private var adsWatched = 0
    @State private var favoriteSlots = 0
    
    var body: some View {
        NavigationView {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                    VStack {
                        Text("Ads Watched: \(adsWatched)/5")
                        
                        ProgressView(value: Float(adsWatched), total: 5)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Button("Watch Ad to Unlock Favorite Slot") {
                            //TODO: AdMob logic to show ad
                            // On ad completion, increment adsWatched
                            adsWatched += 1
                        }
                    }
                    
                        ForEach(coffeeShopData.favoriteShops.prefix(coffeeShopData.maxFavoriteSlots), id: \.id) { coffeeShop in

                        NavigationLink(destination: BrewDetailView(coffeeShop: coffeeShop)) {
                            VStack {
                                BrewPreview(coffeeShop: coffeeShop, showBrewPreview: $showPreview)
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
                    if !storeKit.isAdRemovalPurchased && !userVM.user.isSubscribed {
                        AdBannerView()
                            .frame(width: 320, height: 50)
                    }
                }
                .padding(.all, 16)
                .onChange(of: adsWatched) { newValue in
                    if newValue >= 5 {
                        coffeeShopData.maxFavoriteSlots += 1  // Update the maxFavoriteSlots
                        adsWatched = 0
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
