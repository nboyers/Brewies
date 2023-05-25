//
//  UserCache.swift
//  Brewies
//
//  Created by Noah Boyers on 5/12/23.
//

import Foundation
import MapKit

class UserCache: Encodable, Decodable {
    static let shared = UserCache()
    private init() {}

    // Modify this method to store an array of CoffeeShop objects instead of a single one.
    func cacheCoffeeShops(_ coffeeShops: [CoffeeShop], for location: CLLocationCoordinate2D) {
        if let data = try? JSONEncoder().encode(coffeeShops) {
            let key = keyForLocation(location)
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func getCachedCoffeeShop(id: String) -> CoffeeShop? {
        if let data = UserDefaults.standard.data(forKey: id),
           let coffeeShop = try? JSONDecoder().decode(CoffeeShop.self, from: data) {
            return coffeeShop
        }
        return nil
    }
    
    func cacheCoffeeShop(coffeeShop: CoffeeShop) {
        if let data = try? JSONEncoder().encode(coffeeShop) {
            UserDefaults.standard.set(data, forKey: coffeeShop.id)
        }
    }

    // Retrieve an array of CoffeeShop objects from cache.
    func getCachedCoffeeShops(for location: CLLocationCoordinate2D) -> [CoffeeShop]? {
        let key = keyForLocation(location)
        if let data = UserDefaults.standard.data(forKey: key),
           let coffeeShops = try? JSONDecoder().decode([CoffeeShop].self, from: data) {
            return coffeeShops
        }
        return nil
    }

    // Generate a unique key for each location.
    private func keyForLocation(_ location: CLLocationCoordinate2D) -> String {
        return "coffeeShopsAtLat\(location.latitude)Lon\(location.longitude)"
    }
}

