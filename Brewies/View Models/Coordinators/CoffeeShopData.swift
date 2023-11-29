//
//  CoffeeShopData.swift
//  Brewies
//
//  Created by Noah Boyers on 5/12/23.
//

import Foundation

class CoffeeShopData: ObservableObject {
    static let shared = CoffeeShopData()

    @Published var favoriteShops: [BrewLocation] = [] {
        didSet {
            saveFavoriteShops()
        }
    }

    @Published var maxFavoriteSlots: Int = UserDefaults.standard.integer(forKey: "MaxFavoriteSlots") {
        didSet {
            UserDefaults.standard.set(maxFavoriteSlots, forKey: "MaxFavoriteSlots")
        }
    }

    @Published var adsWatchedCount: Int = UserDefaults.standard.integer(forKey: "AdsWatchedCount") {
        didSet {
            UserDefaults.standard.set(adsWatchedCount, forKey: "AdsWatchedCount")
        }
    }

    @Published var cachedShops: [BrewLocation] = []

    var numberOfFavoriteShops: Int {
        favoriteShops.count
    }
    
    init() {
        loadFavoriteShops()
    }
    
    func addToFavorites(_ coffeeShop: BrewLocation) -> Bool {
        guard favoriteShops.count < maxFavoriteSlots, !favoriteShops.contains(coffeeShop) else {
            return false
        }
        favoriteShops.append(coffeeShop)
        return true
    }
    
    func removeFromFavorites(_ coffeeShop: BrewLocation) {
        favoriteShops.removeAll { $0 == coffeeShop }
        addShopToCache(coffeeShop)
    }

    private func addShopToCache(_ coffeeShop: BrewLocation) {
        if !cachedShops.contains(coffeeShop) {
            var mutableCoffeeShop = coffeeShop
            mutableCoffeeShop.lastAccessDate = Date()
            cachedShops.append(mutableCoffeeShop)
        }
        cachedShops = cachedShops.filter { Date().timeIntervalSince($0.lastAccessDate ?? Date()) < 6 * 30 * 24 * 60 * 60 } // 6 months in seconds
    }
    
    private func saveFavoriteShops() {
//        DispatchQueue.global(qos: .background).async {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(self.favoriteShops) {
                UserDefaults.standard.set(encoded, forKey: "FavoriteShops")
            }
//        }
    }
    
    private func loadFavoriteShops() {
        if let savedShops = UserDefaults.standard.object(forKey: "FavoriteShops") as? Data {
//            DispatchQueue.global(qos: .background).async {
                let decoder = JSONDecoder()
                if let loadedShops = try? decoder.decode([BrewLocation].self, from: savedShops) {
//                    DispatchQueue.main.async {
                        self.favoriteShops = loadedShops
//                    }
                }
//            }
        }
    }
    
    func addFavoriteSlots(_ slots: Int) {
        maxFavoriteSlots += slots
    }

    func removeSubscriptionSlots(_ slots: Int) {
        maxFavoriteSlots = max(0, maxFavoriteSlots - slots)
    }
    
    func hadnleAdsWatchedCount() {
         adsWatchedCount += 1
        if adsWatchedCount >= 3 {
            addFavoriteSlots(1)
            adsWatchedCount = 0
        }
     }
}
