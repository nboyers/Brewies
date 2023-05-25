//
//  YelpResponse.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.
//

import Foundation

struct YelpResponse: Decodable {
    let businesses: [YelpBusiness]
}

struct YelpBusiness: Decodable {
    let id: String
    let name: String
    let photos: [String]?
    let is_closed: Bool
    var is_opened: Bool {
         return !is_closed
     }
    let coordinates: YelpCoordinates
    let rating: Double
    let review_count: Int
    let image_url: String
    let location: YelpLocation
    let display_phone: String
    let url: String
    let transactions: [String]
    let hours: [YelpHours]?
}

struct YelpCoordinates: Decodable {
    let latitude: Double
    let longitude: Double
}

struct YelpLocation: Decodable {
    let address1: String?
    let city: String
    let state: String
    let postal_code: String?
}


struct YelpHours: Decodable, Encodable {
    let open: [YelpOpenHours]
}

struct YelpOpenHours: Decodable, Encodable, Hashable {
    let is_overnight: Bool
    let start: String
    let end: String
    let day: Int

    // Add a computed property for the hours string
    var hoursString: String {
        // Create a format for the start and end time, and return a string.
        // This is just an example, modify as needed.
        let startFormatted = String(start.prefix(2) + ":" + start.suffix(2))
        let endFormatted = String(end.prefix(2) + ":" + end.suffix(2))
        return "\(startFormatted) - \(endFormatted)"
    }
    
    // Conform to Hashable
    static func == (lhs: YelpOpenHours, rhs: YelpOpenHours) -> Bool {
        return lhs.start == rhs.start && lhs.end == rhs.end && lhs.day == rhs.day
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(start)
        hasher.combine(end)
        hasher.combine(day)
    }
}

