//
//  GooglePlacesSearchParams.swift
//  Brewies
//
//  Created by Noah Boyers on 8/18/24.
//

import Foundation

class GooglePlacesSearchParams: ObservableObject {
    @Published var radiusInMeters: Int = 5000 // Start with 5 miles in meters
    @Published var radiusUnit: String = "mi" // Default unit is miles
    @Published var businessType: String = "cafe" // Default to cafe, could be updated to "bar" or others
    @Published var sortBy: String = "distance"
    @Published var priceLevels: [Int] = [] // Use integers for price levels in Google Places (0: Free, 1: Cheap, etc.)

    func resetFilters() {
        radiusInMeters = 5000
        radiusUnit = "mi"
        businessType = "cafe"
        sortBy = "distance"
        priceLevels = []
    }
}
