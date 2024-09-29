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

    // Exclude known chains
    private static var chainCompanyNames: Set<String> = [
        "Starbucks", "McDonald's", "Peet's Coffee", "Dunkin'"
    ]

    private static var undesiredTypes: Set<String> = [
        "gas_station", "convenience_store", "pharmacy", "supermarket",
        "fast_food", "restaurant_chain", "chain_cafe"
    ]

    func fetchNearbyPlaces(
        apiKey: String,
        latitude: Double,
        longitude: Double,
        query: String
    ) async throws -> [BrewLocation] {
        let url = URL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "location", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "radius", value: "\(radiusInMeters)"),
            URLQueryItem(name: "keyword", value: query),
            URLQueryItem(name: "type", value: "cafe"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        if !priceLevels.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "minprice", value: "\(priceLevels.min() ?? 0)"))
            components.queryItems?.append(URLQueryItem(name: "maxprice", value: "\(priceLevels.max() ?? 4)"))
        }

        let request = URLRequest(url: components.url!)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)

        return parseLocations(results: response.results)
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
        let isChain = GooglePlacesAPI.chainCompanyNames.contains { name.lowercased().contains($0.lowercased()) }
        let isUndesiredType = types.contains { GooglePlacesAPI.undesiredTypes.contains($0) }
        return isChain || isUndesiredType
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
