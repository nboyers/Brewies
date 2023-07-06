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
    @Published var  showNoCreditsAlert = false

    @ObservedObject var userViewModel = UserViewModel.shared
    @ObservedObject var locationManager = LocationManager()
    var rewardAdController = RewardAdController()
    
    init() {
        rewardAdController.onUserDidEarnReward = { [weak self] in
            self?.userViewModel.user.credits += 1
            self?.userViewModel.syncCredits()
        }
        rewardAdController.requestIDFA()
        rewardAdController.onAdDidDismissFullScreenContent = { [weak self] in
            // handle ad being dismissed here, update your UI as needed
            self?.showAlert = true
        }
        
    }

    func fetchCoffeeShops(using: YelpSearchParams?, visibleRegionCenter: CLLocationCoordinate2D?) {
        guard let centerCoordinate = visibleRegionCenter ?? locationManager.getCurrentLocation() else {
            showAlert = true
            return
        }

        let selectedRadius = CLLocationDistance(using?.radiusInMeters ?? 5000) // Free gets 3 mile radius

        if userViewModel.user.isSubscribed {
            if let cachedCoffeeShops = UserCache.shared.getCachedCoffeeShops(for: centerCoordinate, radius: selectedRadius) {
                self.coffeeShops = cachedCoffeeShops
                self.selectedCoffeeShop = cachedCoffeeShops.first // Set selectedCoffeeShop to first one
                showBrewPreview = true
                return
            }
        }

        deductUserCredit()
        let yelpAPI = YelpAPI()
        yelpAPI.fetchIndependentCoffeeShops (
            latitude: centerCoordinate.latitude,
            longitude: centerCoordinate.longitude,
            radius: Int(selectedRadius),
            sort_by: using?.sortBy ?? "distance",
            pricing: using?.priceForAPI ?? nil
        ){ [self] coffeeShops in
            if coffeeShops.isEmpty {
                self.showNoCoffeeShopsAlert = true
            } else {
                self.coffeeShops = coffeeShops
                selectedCoffeeShop = coffeeShops.first // Set selectedCoffeeShop to first one
                showBrewPreview = true
                
                // The below line should only be uncommented if you want to cache the results for subscribed users
                UserCache.shared.cacheCoffeeShops(coffeeShops, for: centerCoordinate, radius: selectedRadius)
            }
        }
    }

    

    func handleRewardAd() {
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            rewardAdController.rewardedAd?.present(fromRootViewController: viewController, userDidEarnRewardHandler: {
                // This code will be called when the ad completes
                // Add credit to the user
                self.userViewModel.user.credits += 1
                self.userViewModel.syncCredits()
            })
        } else {
            // If there is no root view controller available, show an alert
            showNoAdsAvailableAlert = true
        }
    }
    
    func deductUserCredit() {
        if userViewModel.user.credits > 0 {
            userViewModel.user.credits -= 1
            userViewModel.syncCredits()
        } else {
            showNoCreditsAlert = true
        }
    }
}
