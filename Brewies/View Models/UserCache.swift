//
//  UserCache.swift
//  Brewies
//
//  Created by Noah Boyers on 5/12/23.
//

import Foundation
import MapKit

class UserCache {
    static let shared = UserCache()
    private let calendar = Calendar.current
    private let cachePeriodInDays = 30
    
    private init() {}
    
    func cacheCoffeeShops(_ coffeeShops: [CoffeeShop], for location: CLLocationCoordinate2D) {
        let key = keyForLocation(location)
        let dateKey = dateKeyForLocation(location)
        do {
            let data = try JSONEncoder().encode(coffeeShops)
            UserDefaults.standard.set(data, forKey: key)
            UserDefaults.standard.set(Date(), forKey: dateKey)
        } catch {
            print("Failed to encode and save coffee shops: \(error)")
        }
    }
    
    func getCachedCoffeeShop(id: String) -> CoffeeShop? {
         if let data = UserDefaults.standard.data(forKey: id),
            let coffeeShop = try? JSONDecoder().decode(CoffeeShop.self, from: data) {
             return coffeeShop
         }
         return nil
     }
    
    func getCachedCoffeeShops(for location: CLLocationCoordinate2D) -> [CoffeeShop]? {
        let key = keyForLocation(location)
        let dateKey = dateKeyForLocation(location)
        
        guard let cacheDate = UserDefaults.standard.object(forKey: dateKey) as? Date else { return nil }
        let daysPassed = calendar.dateComponents([.day], from: cacheDate, to: Date()).day ?? 0

        if daysPassed >= cachePeriodInDays {
            // Cache is older than 30 days, clear it
            UserDefaults.standard.removeObject(forKey: key)
            UserDefaults.standard.removeObject(forKey: dateKey)
            return nil
        } else {
            // Cache is still valid
            if let data = UserDefaults.standard.data(forKey: key) {
                do {
                    let coffeeShops = try JSONDecoder().decode([CoffeeShop].self, from: data)
                    return coffeeShops
                } catch {
                    print("Failed to decode cached coffee shops: \(error)")
                }
            }
        }
        return nil
    }

    private func keyForLocation(_ location: CLLocationCoordinate2D) -> String {
        return "coffeeShopsAtLat\(location.latitude)Lon\(location.longitude)"
    }

    private func dateKeyForLocation(_ location: CLLocationCoordinate2D) -> String {
        return "dateForCoffeeShopsAtLat\(location.latitude)Lon\(location.longitude)"
    }
}
