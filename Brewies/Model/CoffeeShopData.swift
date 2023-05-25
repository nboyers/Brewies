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
    @Published var cachedShops: [CoffeeShop] = []
    
    init() {
        // Load from UserDefaults when the app starts
        loadFavoriteShops()
    }
    
    func addToFavorites(_ coffeeShop: CoffeeShop) {
        if !favoriteShops.contains(coffeeShop) {
            favoriteShops.append(coffeeShop)
        }
        if let index = cachedShops.firstIndex(of: coffeeShop) {
            cachedShops.remove(at: index)
        }
        removeExpiredCachedShops()
    }
    
    func removeFromFavorites(_ coffeeShop: CoffeeShop) {
        if let index = favoriteShops.firstIndex(of: coffeeShop) {
            favoriteShops.remove(at: index)
        }
        if !cachedShops.contains(coffeeShop) {
            var coffeeShop = coffeeShop
            coffeeShop.lastAccessDate = Date()
            cachedShops.append(coffeeShop)
        }
        removeExpiredCachedShops()
    }
    
    private func removeExpiredCachedShops() {
        let currentDate = Date()
        cachedShops.removeAll(where: { Calendar.current.date(byAdding: .hour, value: 72, to: $0.lastAccessDate)! < currentDate })
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
}
