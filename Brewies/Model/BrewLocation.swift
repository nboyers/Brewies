//
//  BrewLocation.swift
//  Brewies
//
//  Created by Noah Boyers on 8/18/24.
//
import Foundation
import CoreLocation

struct BrewLocation: Identifiable, Codable, Equatable, Hashable {
    let id: String // Google Places API uses place_id
    let name: String
    let latitude: Double
    let longitude: Double
    let rating: Double?
    let userRatingsTotal: Int?
    let imageURL: String?
    let photos: [String]?
    let address: String? // Use 'vicinity' or 'formatted_address'
    let phoneNumber: String? // Requires Place Details API
    let website: String? // Requires Place Details API
    let types: [String]? // The place's types (e.g., cafe, bar, etc.)
    let openingHours: OpeningHours?
    let isClosed: Bool // Derived from `business_status`
    let priceLevel: Int? // Google Places provides price_level
    let reviews: [UserReview]? // Requires Place Details API
    var lastAccessDate: Date? // New property to track last access date

    // Nested struct to handle opening hours data
    struct OpeningHours: Codable {
        let openNow: Bool? // Indicates if the place is open now
        let weekdayText: [String]? // Descriptions of hours for each weekday
    }

    // Nested struct to handle user reviews
    struct UserReview: Codable {
        let authorName: String // Name of the author of the review
        let rating: Int // Rating given by the user
        let text: String // Review text
        let relativeTimeDescription: String // Time when the review was written (formatted)
    }

    // Convenience initializer for handling optional data
    init(
        id: String,
        name: String,
        latitude: Double,
        longitude: Double,
        rating: Double? = nil,
        userRatingsTotal: Int? = nil,
        imageURL: String? = nil,
        photos: [String]? = nil,
        address: String? = nil,
        phoneNumber: String? = nil,
        website: String? = nil,
        types: [String]? = nil,
        openingHours: OpeningHours? = nil,
        isClosed: Bool? = nil,
        priceLevel: Int? = nil,
        reviews: [UserReview]? = nil,
        lastAccessDate: Date? = nil // Include the new property in the initializer
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.rating = rating
        self.userRatingsTotal = userRatingsTotal
        self.imageURL = imageURL
        self.photos = photos
        self.address = address
        self.phoneNumber = phoneNumber
        self.website = website
        self.types = types
        self.openingHours = openingHours
        self.isClosed = isClosed ?? false
        self.priceLevel = priceLevel
        self.reviews = reviews
        self.lastAccessDate = lastAccessDate // Initialize the new property
    }
}

extension BrewLocation {
    static func ==(lhs: BrewLocation, rhs: BrewLocation) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
