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
    @Published var  showNoCreditsAlert = false
    
    @ObservedObject var locationManager = LocationManager()
    
    func fetchCoffeeShops(using: YelpSearchParams?, visibleRegionCenter: CLLocationCoordinate2D?) {
        guard let centerCoordinate = visibleRegionCenter ?? locationManager.getCurrentLocation() else {
            showAlert = true
            return
        }
        
        let selectedRadius = CLLocationDistance(using?.radiusInMeters ?? 5000) // Free gets 3 mile radius
        
        if let cachedCoffeeShops = UserCache.shared.getCachedCoffeeShops(for: centerCoordinate, radius: selectedRadius) {
            self.coffeeShops = cachedCoffeeShops
            self.selectedCoffeeShop = cachedCoffeeShops.first // Set selectedCoffeeShop to first one
            showBrewPreview = true
        } else {
            deductUserCredit()
            let yelpAPI = YelpAPI()
            yelpAPI.fetchIndependentCoffeeShops (
                latitude: centerCoordinate.latitude,
                longitude: centerCoordinate.longitude,
                radius: Int(selectedRadius),
                sort_by: using?.sortBy ?? "distance",
                pricing: using?.priceForAPI ?? nil
            ){ [self] coffeeShops in
                if coffeeShops.isEmpty {
                    self.showNoCoffeeShopsAlert = true
                } else {
                    print("\(String(describing: coffeeShops.first?.name))")
                    self.coffeeShops = coffeeShops
                    selectedCoffeeShop = coffeeShops.first // Set selectedCoffeeShop to first one
                    showBrewPreview = true
                    
                    //                    UserCache.shared.cacheCoffeeShops(coffeeShops, for: centerCoordinate, radius: selectedRadius)
                }
            }
        }
    }
    
    
    
    func deductUserCredit() {
        if userCredits > 0 {
            userCredits -= 1
        } else {
            showNoCreditsAlert = true
        }
    }
}
