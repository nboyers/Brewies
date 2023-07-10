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
    let yelpParams = YelpSearchParams()
    var rewardAdController = RewardAdController()
    
    init() {
        rewardAdController.onUserDidEarnReward = { [weak self] in
            self?.userViewModel.addCredits(1)
            self?.userViewModel.syncCredits()
        }
        rewardAdController.requestIDFA()
        rewardAdController.onAdDidDismissFullScreenContent = { [weak self] in
            // handle ad being dismissed here, update your UI as needed
            self?.showAlert = true
        }
        
    }
    
    func fetchCoffeeShops(visibleRegionCenter: CLLocationCoordinate2D?) {
        guard let centerCoordinate = visibleRegionCenter ?? locationManager.getCurrentLocation() else {
            showAlert = true
            return
        }
        let yelpAPI = YelpAPI()
        let selectedRadius = CLLocationDistance(yelpParams.radiusInMeters) // Free gets 3 mile radius
        
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
                        
                        // cache the results for subscribed users
                        UserCache.shared.cacheCoffeeShops(coffeeShops, for: centerCoordinate, radius: selectedRadius)
                    }
                }
                return
            }
            
            if let cachedCoffeeShops = UserCache.shared.getCachedCoffeeShops(for: centerCoordinate, radius: selectedRadius) {
                self.coffeeShops = cachedCoffeeShops
                self.selectedCoffeeShop = cachedCoffeeShops.first // Set selectedCoffeeShop to first one
                showBrewPreview = true
                return
            }
        }
        
        yelpAPI.fetchIndependentCoffeeShops(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude) { [self]  coffeeShops in
            deductUserCredit() // If they make a request, they get deducted
            if coffeeShops.isEmpty {
                self.showNoCoffeeShopsAlert = true
            } else {
                self.coffeeShops = coffeeShops
                selectedCoffeeShop = coffeeShops.first // Set selectedCoffeeShop to first one
                showBrewPreview = true
                
                // cache the results for subscribed users
                UserCache.shared.cacheCoffeeShops(coffeeShops, for: centerCoordinate, radius: selectedRadius)
            }
        }
    }
    
    
    
    func handleRewardAd() {
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            rewardAdController.rewardedAd?.present(fromRootViewController: viewController, userDidEarnRewardHandler: {
                // This code will be called when the ad completes
                // Add credit to the user
                self.userViewModel.addCredits(1)
                self.userViewModel.syncCredits()
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
