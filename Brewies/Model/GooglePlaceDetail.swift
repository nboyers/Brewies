//
//  GooglePlaceDetail.swift
//  Brewies
//
//  Created by Noah Boyers on 9/28/24.
//


import Foundation

// The response model for the Place Details API
struct GooglePlaceDetailResponse: Codable {
    let result: GooglePlaceDetail
    let status: String
}

// The detailed information for a specific place
struct GooglePlaceDetail: Codable {
    let placeId: String
    let name: String
    let geometry: Geometry
    let photos: [Photo]?
    let rating: Double?
    let userRatingsTotal: Int?
    let formattedAddress: String?
    let formattedPhoneNumber: String?
    let website: String?
    let openingHours: OpeningHours?
    let priceLevel: Int?
    let businessStatus: String?
    let types: [String]?
    let reviews: [Review]?

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case geometry
        case photos
        case rating
        case userRatingsTotal = "user_ratings_total"
        case formattedAddress = "formatted_address"
        case formattedPhoneNumber = "formatted_phone_number"
        case website
        case openingHours = "opening_hours"
        case priceLevel = "price_level"
        case businessStatus = "business_status"
        case types
        case reviews
    }
}

// User reviews for the place
struct Review: Codable {
    let authorName: String
    let rating: Int
    let text: String
    let relativeTimeDescription: String

    enum CodingKeys: String, CodingKey {
        case authorName = "author_name"
        case rating
        case text
        case relativeTimeDescription = "relative_time_description"
    }
}
