//
//  BrewLocation.swift
//  Brewies
//
//  Created by Noah Boyers on 11/27/23.
//

import Foundation

struct BrewLocation: Identifiable, Equatable, Codable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let rating: Double
    let reviewCount: Int
    let imageURL: String
    let photos: [String]
    
    let address1: String?
    let address2: String?
    let city: String
    let state: String
    let zipCode: String?
    
    let displayPhone: String
    let url: String
    let transactions: [String]
    let hours: [YelpHours]?
    let isClosed: Bool
    var isFavorite: Bool? = false
    var lastAccessDate: Date? = Date()
    var price: String?
    var review_count: Int
    
    var address: String {
        return "\(address1 ?? ""), \(city), \(state) \(zipCode ?? "")"
    }
    var displayImageUrls: [String] {
        if !photos.isEmpty {
            return photos
        } else {
            return [imageURL]
        }
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
