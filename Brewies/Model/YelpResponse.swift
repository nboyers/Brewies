//
//  YelpResponse.swift
//  Brewies
//
//  Created by Noah Boyers on 6/6/23.
//
import Foundation

struct YelpResponse: Decodable {
    let businesses: [YelpBusiness]
}

struct YelpBusiness: Decodable {
    let id: String
    let alias: String
    let name: String
    let imageUrl: String
    let url: String
    let phone: String
    let displayPhone: String
    let reviewCount: Int
    let categories: [Category]
    let rating: Double
    let location: YelpLocation
    let coordinates: YelpCoordinates
    let photos: [String]?
    let price: String?
    let hours: [YelpHours]?
    let transactions: [String]
    let messaging: Messaging?
    let isClosed: Bool
    enum CodingKeys: String, CodingKey {
        case id, alias, name, url, phone, categories, rating, location, coordinates, photos, price, hours, transactions, messaging
        case imageUrl = "image_url"
        case displayPhone = "display_phone"
        case reviewCount = "review_count"
        case isClosed = "is_closed"
    }
}

struct Category: Codable {
    let alias: String
    let title: String
}

struct YelpCoordinates: Decodable {
    let latitude: Double
    let longitude: Double
}

struct YelpLocation: Decodable {
    let address1: String
    let address2: String?
    let address3: String?
    let city: String
    let zipCode: String
    let country: String
    let state: String
    let displayAddress: [String]
    
    enum CodingKeys: String, CodingKey {
        case address1, address2, address3, city, country, state
        case zipCode = "zip_code"
        case displayAddress = "display_address"
    }
}

struct YelpHours: Codable {
    let open: [YelpOpenHours]
    let hoursType: String
    let isOpenNow: Bool
    
    enum CodingKeys: String, CodingKey {
        case open, hoursType
        case isOpenNow = "is_open_now"
    }
}

struct YelpOpenHours: Codable, Hashable {
    let isOvernight: Bool
    let start: String
    let end: String
    let day: Int
    
    enum CodingKeys: String, CodingKey {
        case start, end, day
        case isOvernight = "is_overnight"
    }
}

struct Messaging: Codable {
    let url: String
    let useCaseText: String
    
    enum CodingKeys: String, CodingKey {
        case url
        case useCaseText = "use_case_text"
    }
}
