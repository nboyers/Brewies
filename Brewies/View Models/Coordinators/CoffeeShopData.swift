//
//  CoffeeShopData.swift
//  Brewies
//
//  Created by Noah Boyers on 5/12/23.
//

import Foundation

class CoffeeShopData: ObservableObject {
    static let shared = CoffeeShopData()
    
    @Published var favoriteShops: [CoffeeShop] = [] {
        didSet {
            saveFavoriteShops()
        }
    }
    
    @Published var maxFavoriteSlots: Int = UserDefaults.standard.integer(forKey: "MaxFavoriteSlots") {
        didSet {
            print("maxFavoriteSlots changed to \(maxFavoriteSlots)")
            UserDefaults.standard.set(maxFavoriteSlots, forKey: "MaxFavoriteSlots")
            print("maxFavoriteSlots changed to \(maxFavoriteSlots)")
        }
    }



    
    @Published var cachedShops: [CoffeeShop] = []

    var numberOfFavoriteShops: Int {
        return favoriteShops.count
    }

    
    init() {
        // Load from UserDefaults when the app starts
        loadFavoriteShops()
        loadMaxFavoriteSlots()

    }
    
    func addToFavorites(_ coffeeShop: CoffeeShop) -> Bool {
        if favoriteShops.count >= maxFavoriteSlots {
            return false
        }
        
        if !favoriteShops.contains(coffeeShop) {
            favoriteShops.append(coffeeShop)
        }
        removeExpiredCachedShops()
        return true
    }
    
    func removeFromFavorites(_ coffeeShop: CoffeeShop) {
        if let index = favoriteShops.firstIndex(of: coffeeShop) {
            favoriteShops.remove(at: index)
        }
        if !cachedShops.contains(coffeeShop) {
            var mutableCoffeeShop = coffeeShop
            mutableCoffeeShop.lastAccessDate = Date()
            cachedShops.append(mutableCoffeeShop)
        }
        removeExpiredCachedShops()
    }

    
    private func removeExpiredCachedShops() {
        let currentDate = Date()
        cachedShops.removeAll(where: { Calendar.current.date(byAdding: .month, value: 6, to: $0.lastAccessDate ?? Date.now)! < currentDate })
    }
    
    private func saveFavoriteShops() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(favoriteShops) {
            UserDefaults.standard.set(encoded, forKey: "FavoriteShops")
        }
    }
    
    private func loadFavoriteShops() {
        if let savedShops = UserDefaults.standard.data(forKey: "FavoriteShops") {
            let decoder = JSONDecoder()
            if let loadedShops = try? decoder.decode([CoffeeShop].self, from: savedShops) {
                favoriteShops = loadedShops
            }
        }
    }
    private func loadMaxFavoriteSlots() {
        if let savedMaxFavoriteSlots = UserDefaults.standard.value(forKey: "MaxFavoriteSlots") as? Int {
            maxFavoriteSlots = savedMaxFavoriteSlots
        }
    }
    
    func addFavoriteSlots(_ slots: Int) {
        DispatchQueue.main.async {
            self.maxFavoriteSlots += slots
        }
        UserDefaults.standard.set(self.maxFavoriteSlots, forKey: "MaxFavoriteSlots")
    }

    func removeSubscriptionSlots(_ slots: Int) {
        DispatchQueue.main.async {
            self.maxFavoriteSlots = max(0, self.maxFavoriteSlots - slots)  // Ensure it doesn't go negative
        }
        UserDefaults.standard.set(self.maxFavoriteSlots, forKey: "MaxFavoriteSlots")
    }

}
