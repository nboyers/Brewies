//
//  GooglePlaceResult.swift
//  Brewies
//
//  Created by Noah Boyers on 08/18/24.
//

import Foundation

struct GooglePlacesResponse: Codable {
    let results: [GooglePlaceResult]
    let status: String
    let nextPageToken: String?

    enum CodingKeys: String, CodingKey {
        case results
        case status
        case nextPageToken = "next_page_token"
    }
}

struct GooglePlaceResult: Codable {
    let placeId: String
    let name: String
    let geometry: Geometry
    let photos: [Photo]?
    let rating: Double?
    let userRatingsTotal: Int?
    let vicinity: String?
    let openingHours: OpeningHours?
    let priceLevel: Int?
    let businessStatus: String?
    let types: [String]?

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case geometry
        case photos
        case rating
        case userRatingsTotal = "user_ratings_total"
        case vicinity
        case openingHours = "opening_hours"
        case priceLevel = "price_level"
        case businessStatus = "business_status"
        case types
    }
}

struct Geometry: Codable {
    let location: Location
}

struct Location: Codable {
    let lat: Double
    let lng: Double
}

struct Photo: Codable {
    let photoReference: String
    let width: Int?
    let height: Int?
    let htmlAttributions: [String]

    enum CodingKeys: String, CodingKey {
        case photoReference = "photo_reference"
        case width
        case height
        case htmlAttributions = "html_attributions"
    }
}

struct OpeningHours: Codable {
    let openNow: Bool?
    let weekdayText: [String]?

    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
        case weekdayText = "weekday_text"
    }
}
