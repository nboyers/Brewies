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
    
    @Published var userViewModel = UserViewModel.shared
    @Published var locationManager = LocationManager()
    @Published var apiKeysViewModel = APIKeysViewModel.shared
    
    private var rewardAdController = RewardAdController()
    var yelpParams: YelpSearchParams
    
    init(yelpParams: YelpSearchParams) {
        self.yelpParams = yelpParams
        rewardAdController.onUserDidEarnReward = { [weak self] in
            DispatchQueue.main.async {
                self?.userViewModel.addCredits(1)
                self?.userViewModel.syncCredits(accountStatus: "")
            }
        }
        clearOldCache()
    }

    func fetchCoffeeShops(visibleRegionCenter: CLLocationCoordinate2D?) {
        deductUserCredit()
        
        guard let centerCoordinate = visibleRegionCenter ?? locationManager.getCurrentLocation() else {
            DispatchQueue.main.async {
                self.showAlert = true
            }
            return
        }
        
        let cacheKey = "\(centerCoordinate.latitude),\(centerCoordinate.longitude)"
        
        if let cachedShops = retrieveFromCache(forKey: cacheKey), !cachedShops.isEmpty {
            DispatchQueue.main.async {
                self.coffeeShops = cachedShops
                self.selectedCoffeeShop = cachedShops.first
                self.showBrewPreview = true
                self.fetchedFromCache = true
            }
            return
        }
        
        apiKeysViewModel.fetchAPIKeys { [weak self] API in
            guard let self = self else { return }
            let yelpAPI = YelpAPI(yelpParams: self.yelpParams)
            yelpAPI.fetchIndependentCoffeeShops(apiKey: API?.YELP_API ?? "KEYLESS", latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude) { shops in
                DispatchQueue.main.async {
                    self.processCoffeeShops(coffeeShops: shops, cacheKey: cacheKey)
                }
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
    
    private func clearOldCache() {
        let userDefaults = UserDefaults.standard
        let cacheKeys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasSuffix("-date") }
        let currentDate = Date()
        let expirationInterval: TimeInterval = 86400 // 24 hours
        
        DispatchQueue.global(qos: .background).async {
            for key in cacheKeys {
                if let cacheDate = userDefaults.object(forKey: key) as? Date,
                   currentDate.timeIntervalSince(cacheDate) > expirationInterval {
                    let dataKey = String(key.dropLast("-date".count))
                    userDefaults.removeObject(forKey: dataKey)
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
        DispatchQueue.main.async { [self] in
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let viewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                rewardAdController.present(from: viewController, rewardType: reward)
            }
        }
    }
    
    func deductUserCredit() {
        DispatchQueue.main.async { [self] in
            if userViewModel.user.credits > 0 {
                userViewModel.subtractCredits(1)
            } else {
                showNoCreditsAlert = true
            }
        }
    }
}
