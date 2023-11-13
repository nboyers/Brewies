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
    @Published var fetchedFromCache = false
    
    // Changed from @ObservedObject to @Published to ensure updates propagate to the view as expected.
    @Published var userViewModel = UserViewModel.shared
    @Published var locationManager = LocationManager()
    @Published var apiKeysViewModel = APIKeysViewModel.shared
    
    private var rewardAdController = RewardAdController()
    var yelpParams: YelpSearchParams
    
    init(yelpParams: YelpSearchParams) {
        self.yelpParams = yelpParams
        rewardAdController.onUserDidEarnReward = { [weak self] in
            self?.userViewModel.addCredits(1)
            self?.userViewModel.syncCredits(accountStatus: "")
        }
        rewardAdController.onAdDidDismissFullScreenContent = { [weak self] in
            self?.showAlert = true
        }
        clearOldCache()
    }
    
    func fetchCoffeeShops(visibleRegionCenter: CLLocationCoordinate2D?) {
        //Reduce the user credit regardless if it is cached or not 
        deductUserCredit()
        
        // Immediate deduction of credit is moved to where it's confirmed needed
        guard let centerCoordinate = visibleRegionCenter ?? locationManager.getCurrentLocation() else {
            showAlert = true
            return
        }
        
        let cacheKey = "\(centerCoordinate.latitude),\(centerCoordinate.longitude)"
        
        // Attempt to fetch from cache before making a network call
        if let cachedShops = retrieveFromCache(forKey: cacheKey), !cachedShops.isEmpty {
            // Use main thread for UI updates
            DispatchQueue.main.async {
                self.coffeeShops = cachedShops
                self.selectedCoffeeShop = cachedShops.first
                self.showBrewPreview = true
                self.fetchedFromCache = true
            }
            return // Exit early if we have cache data
        }
        
        // User credit deduction and API call are made only if cache is missing or empty
        apiKeysViewModel.fetchAPIKeys { [weak self] API in
            guard let self = self else { return }
            let yelpAPI = YelpAPI(yelpParams: self.yelpParams)
            yelpAPI.fetchIndependentCoffeeShops(apiKey: API?.YELP_API ?? "KEYLESS", latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude) { shops in
                self.processCoffeeShops(coffeeShops: shops, cacheKey: cacheKey)
            }
        }
    }

    
    private func processCoffeeShops(coffeeShops: [CoffeeShop], cacheKey: String) {
        saveToCache(coffeeShops: coffeeShops, forKey: cacheKey)
        self.coffeeShops = coffeeShops
        self.selectedCoffeeShop = coffeeShops.first
        self.showBrewPreview = true
    }
    
    private func saveToCache(coffeeShops: [CoffeeShop], forKey key: String) {
        // Use asynchronous saving to not block the main thread
        DispatchQueue.global(qos: .background).async {
            let data = try? JSONEncoder().encode(coffeeShops)
            UserDefaults.standard.set(data, forKey: key)
            UserDefaults.standard.set(Date(), forKey: "\(key)-date")
        }
    }
    
    private func clearOldCache() {
        let userDefaults = UserDefaults.standard
        let keys = userDefaults.dictionaryRepresentation().keys.filter { $0.contains("-date") }
        // Perform date calculations on a background thread to prevent blocking the UI
        DispatchQueue.global(qos: .background).async {
            keys.forEach { key in
                if let cacheDate = userDefaults.object(forKey: key) as? Date, Date().timeIntervalSince(cacheDate) >= 86400 {
                    userDefaults.removeObject(forKey: key.replacingOccurrences(of: "-date", with: ""))
                    userDefaults.removeObject(forKey: key)
                }
            }
        }
    }

    
    private func retrieveFromCache(forKey key: String) -> [CoffeeShop]? {
        if let data = UserDefaults.standard.data(forKey: key) {
            return try? JSONDecoder().decode([CoffeeShop].self, from: data)
        }
        return nil
    }

    
    func handleRewardAd(reward: String) {
      
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let viewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                rewardAdController.rewardedAd?.present(fromRootViewController: viewController, userDidEarnRewardHandler: { [weak self] in
                    guard let self = self else { return }
                    
                    switch reward {
                    case "credits":
                        self.userViewModel.addCredits(1)
                    case "favorites":
                        self.adsWatched += 1
                        if self.adsWatched >= 3 {
                            CoffeeShopData.shared.addFavoriteSlots(1)
                            self.adsWatched = 0
                        }
                    case "check_in":
                        self.userViewModel.saveStreakData()
                    default:
                        break
                    }
                })
            } else {
                self.showNoAdsAvailableAlert = true
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
