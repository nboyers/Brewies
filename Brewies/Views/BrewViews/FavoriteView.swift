//
//  FavoriteView.swift
//  Brewies
//
//  Created by Noah Boyers on 5/12/23.
//

import SwiftUI
import AppTrackingTransparency

struct FavoritesView: View {
    @EnvironmentObject var contentVM: ContentViewModel
    @ObservedObject var rewardAdController = RewardAdController()
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var selectedCoffeeShop: SelectedCoffeeShop
    @StateObject var sharedAlertVM = SharedAlertViewModel()
    @ObservedObject var coffeeShopData = CoffeeShopData.shared
    @ObservedObject var storeKit = StoreKitManager()
    
    @Binding var showPreview: Bool
    @State private var showRemovalConfirmationAlert = false
    @State private var toRemoveCoffeeShop: BrewLocation?

    @Binding var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        Text("Ads Watched: \(coffeeShopData.adsWatchedCount)/3")
                            .font(.headline)
                        
                        ProgressView(value: Float(coffeeShopData.adsWatchedCount), total: 3)
                                     .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                                     .accentColor(Color.blue)
                                     .background(Color.gray.opacity(0.2).cornerRadius(5))
                                     .cornerRadius(5)
                                 
                        
                        Button(action: {
                            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                                ATTrackingManager.requestTrackingAuthorization { [self] status in
                                    switch status {
                                    case .authorized:
                                        // Here, you can continue with ad loading as the user has given permission
                                        self.contentVM.handleRewardAd(reward: "favorites")
                                    case .denied, .restricted:
                                        // Handle the case where permission is denied
                                        self.contentVM.handleRewardAd(reward: "favorites")
                                        break
                                    case .notDetermined:
                                        // The user has not decided on permission
                                        self.contentVM.handleRewardAd(reward: "favorites")
                                        break
                                    @unknown default:
                                        break
                                    }
                                }
                            } else {
                                self.contentVM.handleRewardAd(reward: "favorites")
                            }
                            
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
                    if !storeKit.storeStatus.isAdRemovalPurchased && !userVM.user.isSubscribed {
                        AdBannerView()
                            .frame(width: 320, height: 50)
                    }
                }
                .padding(.all, 16)
                .onChange(of: coffeeShopData.adsWatchedCount) { newValue in
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
