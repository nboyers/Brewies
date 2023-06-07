//
//  YelpBusiness.swift
//  Brewies
//
//  Created by Noah Boyers on 6/6/23.
//

import Foundation


struct YelpResponse: Codable {
    let businesses: [Business]
}

struct Business: Codable {
    let id: String
    let alias: String
    let name: String
    let imageUrl: String
    let isClaimed: Bool
    let isClosed: Bool
    let url: String
    let phone: String
    let displayPhone: String
    let reviewCount: Int
    let categories: [Category]
    let rating: Double
    let location: Location
    let coordinates: Coordinates
    let photos: [String]
    let price: String
    let hours: [Hours]
    let transactions: [String]
    let messaging: Messaging
    
    enum CodingKeys: String, CodingKey {
        case id, alias, name, isClaimed, isClosed, url, phone, reviewCount, categories, rating, location, coordinates, photos, price, hours, transactions, messaging
        case imageUrl = "image_url"
        case displayPhone = "display_phone"
    }
}

struct Category: Codable {
    let alias: String
    let title: String
}

struct Location: Codable {
    let address1: String
    let address2: String
    let address3: String?
    let city: String
    let zipCode: String
    let country: String
    let state: String
    let displayAddress: [String]
    let crossStreets: String
    
    enum CodingKeys: String, CodingKey {
        case address1, address2, address3, city, country, state, displayAddress, crossStreets
        case zipCode = "zip_code"
    }
}

struct Coordinates: Codable {
    let latitude: Double
    let longitude: Double
}

struct Hours: Codable {
    let open: [Open]
    let hoursType: String
    let isOpenNow: Bool
    
    enum CodingKeys: String, CodingKey {
        case open, hoursType
        case isOpenNow = "is_open_now"
    }
}

struct Open: Codable {
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
