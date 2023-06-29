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
    @Published var userCredits: Int = 10
    @Published var showAlert = false
    @Published var showBrewPreview = false
    @Published var searchQuery: String = ""
    @Published var showNoCoffeeShopsAlert = false
    @Published var showNoAdsAvailableAlert = false
    
    @ObservedObject private var locationManager = LocationManager()
    
    var visibleRegionCenter: CLLocationCoordinate2D?
    
    
    func fetchCoffeeShops(using: YelpSearchParams?) {
        guard let centerCoordinate = visibleRegionCenter ?? locationManager.getCurrentLocation() else {
            showAlert = true
            return
        }
        
        let selectedRadius = CLLocationDistance(using?.radiusInMeters ?? 4828) // Free gets 3 mile radius
        
        if let cachedCoffeeShops = UserCache.shared.getCachedCoffeeShops(for: centerCoordinate, radius: selectedRadius) {
            self.coffeeShops = cachedCoffeeShops
            self.selectedCoffeeShop = cachedCoffeeShops.first // Set selectedCoffeeShop to first one
            showBrewPreview = true
        } else {
            let yelpAPI = YelpAPI()
            yelpAPI.fetchIndependentCoffeeShops (
                latitude: centerCoordinate.latitude,
                longitude: centerCoordinate.longitude,
                radius: Int(selectedRadius),
                sort_by: using?.sortBy ?? "best_match"
            ) { coffeeShops in
                if coffeeShops.isEmpty {
                    self.showNoCoffeeShopsAlert = true
                } else {
                    self.coffeeShops = coffeeShops
                    self.selectedCoffeeShop = coffeeShops.first // Set selectedCoffeeShop to first one
                    self.showBrewPreview = true
                    UserCache.shared.cacheCoffeeShops(coffeeShops, for: centerCoordinate, radius: selectedRadius)
                }
            }
        }
    }
    
    
    
    func deductUserCredit() {
        if userCredits > 0 {
            userCredits -= 1
        } else {
            showAlert = true
        }
    }
}
