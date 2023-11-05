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
    
    @ObservedObject var userViewModel = UserViewModel.shared
    @ObservedObject var locationManager = LocationManager()
    @ObservedObject var apiKeysViewModel = APIKeysViewModel.shared
    
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
        deductUserCredit()
        guard let centerCoordinate = visibleRegionCenter ?? locationManager.getCurrentLocation() else {
            showAlert = true
            return
        }
        
        let cacheKey = "\(centerCoordinate.latitude),\(centerCoordinate.longitude)"
        
        if let cachedShops = retrieveFromCache(forKey: cacheKey) {
            self.coffeeShops = cachedShops
            self.selectedCoffeeShop = cachedShops.first
            self.showBrewPreview = true
            self.fetchedFromCache = true
            return
        }
        
        apiKeysViewModel.fetchAPIKeys { [self] API in
            let yelpAPI = YelpAPI(yelpParams: yelpParams)
            yelpAPI.fetchIndependentCoffeeShops(apiKey: API?.YELP_API ?? "KEYLESS", latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude) { [self] coffeeShops in
                self.fetchedFromCache = false
                processCoffeeShops(coffeeShops: coffeeShops, cacheKey: cacheKey)
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
        let data = try? JSONEncoder().encode(coffeeShops)
        UserDefaults.standard.set(data, forKey: key)
        UserDefaults.standard.set(Date(), forKey: "\(key)-date")
    }
    
    private func retrieveFromCache(forKey key: String) -> [CoffeeShop]? {
        if let data = UserDefaults.standard.data(forKey: key) {
            return try? JSONDecoder().decode([CoffeeShop].self, from: data)
        }
        return nil
    }

    
    private func clearOldCache() {
        let userDefaults = UserDefaults.standard
        for key in userDefaults.dictionaryRepresentation().keys {
            if key.contains("-date"), let cacheDate = userDefaults.object(forKey: key) as? Date, Date().timeIntervalSince(cacheDate) >= 86400 {
                let dataKey = key.replacingOccurrences(of: "-date", with: "")
                userDefaults.removeObject(forKey: dataKey)
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    func handleRewardAd(reward: String) {
        DispatchQueue.main.async { [self] in // Make sure you're on the main thread
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
    }

    func deductUserCredit() {
        if userViewModel.user.credits > 0 {
            userViewModel.subtractCredits(1)
        } else {
            showNoCreditsAlert = true
        }
    }
}
