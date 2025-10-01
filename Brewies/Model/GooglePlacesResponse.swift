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

// New Google Places API (New) models
struct NewGooglePlacesResponse: Codable {
    let places: [NewGooglePlace]?
}

struct NewGooglePlace: Codable {
    let id: String
    let displayName: DisplayName?
    let location: NewLocation?
    let rating: Double?
    let userRatingCount: Int?
    let photos: [NewPhoto]?
    let formattedAddress: String?
    let types: [String]?
    let businessStatus: String?
    let priceLevel: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, displayName, location, rating, userRatingCount, photos, formattedAddress, types, businessStatus, priceLevel
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decodeIfPresent(DisplayName.self, forKey: .displayName)
        location = try container.decodeIfPresent(NewLocation.self, forKey: .location)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        userRatingCount = try container.decodeIfPresent(Int.self, forKey: .userRatingCount)
        photos = try container.decodeIfPresent([NewPhoto].self, forKey: .photos)
        formattedAddress = try container.decodeIfPresent(String.self, forKey: .formattedAddress)
        types = try container.decodeIfPresent([String].self, forKey: .types)
        businessStatus = try container.decodeIfPresent(String.self, forKey: .businessStatus)
        
        // Handle priceLevel as either string or int
        if let priceLevelString = try? container.decodeIfPresent(String.self, forKey: .priceLevel) {
            priceLevel = Int(priceLevelString)
        } else {
            priceLevel = try container.decodeIfPresent(Int.self, forKey: .priceLevel)
        }
    }
}

struct DisplayName: Codable {
    let text: String
}

struct NewLocation: Codable {
    let latitude: Double
    let longitude: Double
}

struct NewPhoto: Codable {
    let name: String
}
