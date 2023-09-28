//
//  ContentViewModel.swift
//  Brewies
//
//  Created by Noah Boyers on 6/29/23.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

class ContentViewModel: ObservableObject {
    @Published var coffeeShops: [CoffeeShop] = []
    @Published var selectedCoffeeShop: CoffeeShop?
    @Published var showAlert = false
    @Published var showBrewPreview = false
    @Published var searchQuery: String = ""
    @Published var showNoCoffeeShopsAlert = false
    @Published var showNoAdsAvailableAlert = false
    @Published var showNoCreditsAlert = false
    @Published var adsWatched = 0

    @ObservedObject var userViewModel = UserViewModel.shared
    @ObservedObject var locationManager = LocationManager()
    
    
    private var rewardAdController = RewardAdController()
    var yelpParams: YelpSearchParams
    
    
    init(yelpParams: YelpSearchParams) {
        self.yelpParams = yelpParams
        rewardAdController.onUserDidEarnReward = { [weak self] in
            self?.userViewModel.addCredits(1)
            self?.userViewModel.syncCredits()
        }
        rewardAdController.requestIDFA()
        rewardAdController.onAdDidDismissFullScreenContent = { [weak self] in
            self?.showAlert = true
        }
        
    }
    
    func fetchCoffeeShops(visibleRegionCenter: CLLocationCoordinate2D?) {
        guard let centerCoordinate = visibleRegionCenter ?? locationManager.getCurrentLocation() else {
            showAlert = true
            return
        }
        let yelpAPI = YelpAPI(yelpParams: yelpParams)
    
        //This is where the app is not extendin the
        if userViewModel.user.isSubscribed {
            if yelpParams.radiusInMeters > 5000 { //If the user created a higher search raduis, resend the request
                yelpAPI.fetchIndependentCoffeeShops(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude) { [self]  coffeeShops in
                    deductUserCredit() // If they make a request, they get deducted
                    if coffeeShops.isEmpty {
                        self.showNoCoffeeShopsAlert = true
                    } else {
                        self.coffeeShops = coffeeShops
                        selectedCoffeeShop = coffeeShops.first // Set selectedCoffeeShop to first one
                        showBrewPreview = true
                    }
                }
                return
            }
            
//            if let cachedCoffeeShops = UserCache.shared.getCachedCoffeeShops(for: centerCoordinate, radius: selectedRadius) {
//                self.coffeeShops = cachedCoffeeShops
//                self.selectedCoffeeShop = cachedCoffeeShops.first // Set selectedCoffeeShop to first one
//                showBrewPreview = true
//                return
//            }
        }
        
        yelpAPI.fetchIndependentCoffeeShops(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude) { [self]  coffeeShops in
            deductUserCredit() // If they make a request, they get deducted
            if coffeeShops.isEmpty {
                self.showNoCoffeeShopsAlert = true
            } else {
                self.coffeeShops = coffeeShops
                selectedCoffeeShop = coffeeShops.first // Set selectedCoffeeShop to first one
                showBrewPreview = true
            }
        }
    }
    
    func handleRewardAd(reward: String) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            rewardAdController.rewardedAd?.present(fromRootViewController: viewController, userDidEarnRewardHandler: { [self] in
                // This code will be called when the ad completes
                // Add credit to the user
                switch reward {
                case "credits":
                    userViewModel.addCredits(1)
                    break
                    
                case "favorites":
                    adsWatched += 1
                    if adsWatched >= 3 {
                        CoffeeShopData.shared.addFavoriteSlots(1)
                        adsWatched = 0
                    }
                    
                    break
                default:
                    break
                }
                    
            })
        } else {
            // If there is no root view controller available, show an alert
            showNoAdsAvailableAlert = true
        }
    }

    
    func deductUserCredit() {
        if userViewModel.user.credits > 0 {
            userViewModel.subtractCredits(1)
        } else {
            showNoCreditsAlert = true
        }
    }
}
