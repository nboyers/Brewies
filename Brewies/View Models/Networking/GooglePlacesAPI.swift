//
//  GooglePlacesAPI.swift
//  Brewies
//
//  Created by Noah Boyers on 8/18/24.
//

import Foundation
import Combine


class GooglePlacesAPI: ObservableObject {
    @Published var googlePlacesParams = GooglePlacesSearchParams() { didSet { updateParams() } }

    var favoriteCoffeeShops: [BrewLocation] = []
    var cancellables: Set<AnyCancellable> = []
    var radiusInMeters: Int = 5000
    var sortBy: String = "prominence"
    var priceLevels: [Int] = []

    init(googlePlacesParams: GooglePlacesSearchParams) {
        self.googlePlacesParams = googlePlacesParams
    }

    private func updateParams() {
        radiusInMeters = googlePlacesParams.radiusInMeters
        sortBy = googlePlacesParams.sortBy
        priceLevels = googlePlacesParams.priceLevels
    }

    // Exclude non-coffee/brewery place types (valid Google Places API types)
    private static var excludedTypes: Set<String> = [
        "gas_station", "convenience_store", "pharmacy", "supermarket", 
        "department_store", "shopping_mall", "meal_takeaway", "meal_delivery",
        "car_dealer", "car_repair", "bank", "atm", "hospital", "dentist",
        "school", "university", "gym", "beauty_salon", "laundry","breakfast_restaurant", "fast_food_restaurant",
        "food_court", "liquor_store", "movie_theater", "truck_stop", "lodging"
    ]
    
    // Only include these coffee/brewery related types
    private static var desiredTypes: Set<String> = [
        "cafe", "coffee_shop", "bakery", "restaurant", "bar", "night_club"
    ]

    func fetchNearbyPlaces(
        apiKey: String,
        latitude: Double,
        longitude: Double,
        query: String
    ) async throws -> [BrewLocation] {
        let url = URL(string: "https://places.googleapis.com/v1/places:searchNearby")!
        
        let placeType = query.lowercased().contains("brewery") || query.lowercased().contains("breweries") ? "bar" : "cafe"
        
        let requestBody: [String: Any] = [
            "includedTypes": [placeType],
            "excludedTypes": Array(GooglePlacesAPI.excludedTypes),
            "maxResultCount": 20,
            "locationRestriction": [
                "circle": [
                    "center": [
                        "latitude": latitude,
                        "longitude": longitude
                    ],
                    "radius": Double(radiusInMeters)
                ]
            ],
            "languageCode": "en"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.photos,places.types,places.currentOpeningHours,places.businessStatus,places.priceLevel,places.id", forHTTPHeaderField: "X-Goog-FieldMask")
        
        let bundleId = Bundle.main.bundleIdentifier ?? "com.nobosoftware.Brewies"
        request.setValue(bundleId, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("New Google Places API URL: \(url)")
        print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "none")")

        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status Code: \(httpResponse.statusCode)")
        }
        
        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let places = jsonResponse["places"] as? [[String: Any]] {
                print("Found \(places.count) places")
                let allLocations = parseNewAPILocations(places: places)
                let filteredLocations = filterByDistance(locations: allLocations, centerLat: latitude, centerLng: longitude)
                print("After distance filtering: \(filteredLocations.count) places")
                return filteredLocations
            } else if let error = jsonResponse["error"] {
                print("API Error: \(error)")
            }
        }
        
        return []
    }

    private func parseNewAPILocations(places: [[String: Any]]) -> [BrewLocation] {
        var locations: [BrewLocation] = []

        for place in places {
            guard let id = place["id"] as? String,
                  let displayName = place["displayName"] as? [String: Any],
                  let name = displayName["text"] as? String,
                  let location = place["location"] as? [String: Any],
                  let latitude = location["latitude"] as? Double,
                  let longitude = location["longitude"] as? Double else {
                continue
            }
            
            let rating = place["rating"] as? Double
            let userRatingCount = place["userRatingCount"] as? Int
            let formattedAddress = place["formattedAddress"] as? String
            let types = place["types"] as? [String]
            let priceLevel = place["priceLevel"] as? Int
            
            // Parse photos from new API format
            var photoReferences: [String] = []
            if let photos = place["photos"] as? [[String: Any]] {
                for photo in photos {
                    if let name = photo["name"] as? String {
                        photoReferences.append(name)
                    }
                }
            }
            
            // Skip excluded chains
            if !isExcludedChain(name: name, types: types ?? []) {
                let brewLocation = BrewLocation(
                    id: id,
                    name: name,
                    latitude: latitude,
                    longitude: longitude,
                    rating: rating,
                    userRatingsTotal: userRatingCount,
                    imageURL: photoReferences.first,
                    photos: photoReferences.isEmpty ? nil : photoReferences,
                    address: formattedAddress,
                    phoneNumber: nil,
                    website: nil,
                    types: types,
                    openingHours: nil,
                    isClosed: false,
                    priceLevel: priceLevel,
                    reviews: nil
                )
                locations.append(brewLocation)
            }
        }

        return locations
    }
    
    private func filterByDistance(locations: [BrewLocation], centerLat: Double, centerLng: Double) -> [BrewLocation] {
        return locations.filter { location in
            let distance = calculateDistance(
                lat1: centerLat, lng1: centerLng,
                lat2: location.latitude, lng2: location.longitude
            )
            return distance <= Double(radiusInMeters)
        }
    }
    
    private func calculateDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double {
        let earthRadius = 6371000.0 // Earth's radius in meters
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLng = (lng2 - lng1) * .pi / 180.0
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) * sin(dLng/2) * sin(dLng/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return earthRadius * c
    }
    
    private func parseLocations(results: [GooglePlaceResult]) -> [BrewLocation] {
        var locations: [BrewLocation] = []

        for result in results where !isExcludedChain(name: result.name, types: result.types ?? []) {
            let location = BrewLocation(
                id: result.placeId,
                name: result.name,
                latitude: result.geometry.location.lat,
                longitude: result.geometry.location.lng,
                rating: result.rating,
                userRatingsTotal: result.userRatingsTotal,
                imageURL: result.photos?.first?.photoReference,
                photos: result.photos?.compactMap { $0.photoReference },
                address: result.vicinity,
                phoneNumber: nil,
                website: nil,
                types: result.types,
                openingHours: result.openingHours != nil ? BrewLocation.OpeningHours(
                    openNow: result.openingHours?.openNow,
                    weekdayText: result.openingHours?.weekdayText
                ) : nil,
                isClosed: result.businessStatus == "CLOSED_TEMPORARILY" || result.businessStatus == "CLOSED_PERMANENTLY",
                priceLevel: result.priceLevel,
                reviews: nil
            )
            locations.append(location)
        }

        return locations
    }

    private func isExcludedChain(name: String, types: [String]) -> Bool {
        let lowercaseName = name.lowercased()
        
        // Filter out fast food chains and gas stations by name
        let isFastFood = lowercaseName.contains("mcdonald") || lowercaseName.contains("burger") || lowercaseName.contains("kfc") || lowercaseName.contains("subway")
        let isGasStation = lowercaseName.contains("shell") || lowercaseName.contains("chevron") || lowercaseName.contains("bp") || lowercaseName.contains("exxon")
        let isConvenienceStore = lowercaseName.contains("mart") || lowercaseName.contains("7-eleven") || lowercaseName.contains("circle k")
        
        // Filter based on place types
        let hasExcludedType = types.contains { GooglePlacesAPI.excludedTypes.contains($0) }
        
        return isFastFood || isGasStation || isConvenienceStore || hasExcludedType
    }

    func fetchPlaceDetails(id: String, apiKey: String) async throws -> GooglePlaceDetail {
        let url = URL(string: "https://maps.googleapis.com/maps/api/place/details/json")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "place_id", value: id),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "fields", value: "name,rating,formatted_phone_number,formatted_address,geometry,photo,opening_hours,price_level,website")
        ]

        let request = URLRequest(url: components.url!)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GooglePlaceDetailResponse.self, from: data)

        return response.result
    }
}
