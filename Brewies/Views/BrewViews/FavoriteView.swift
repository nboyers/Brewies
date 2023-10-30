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
    @EnvironmentObject var selectedCoffeeShop: SelectedCoffeeShop
    
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
                    VStack(spacing: 10) {
                        Text("Ads Watched: \(contentVM.adsWatched)/3")
                            .font(.headline)
                        
                        ProgressView(value: Float(contentVM.adsWatched), total: 3)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                            .accentColor(Color.blue)
                            .background(Color.gray.opacity(0.2).cornerRadius(5))
                            .cornerRadius(5)
                        
                        Button(action: {
                            contentVM.handleRewardAd(reward: "favorites")
                        }) {
                            HStack {
                                Image(systemName: "video")
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                Text("Watch Ad to Unlock Favorite Slot")
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
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
                        .navigationBarBackButtonHidden(true)
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
        .navigationBarBackButtonHidden(true)
    }
}
