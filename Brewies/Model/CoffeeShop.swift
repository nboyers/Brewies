//
//  CoffeeShop.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.
//

import Foundation


struct CoffeeShop: Identifiable, Equatable, Codable {
    
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let rating: Double
    let reviewCount: Int
    let imageURL: String
    let photos: [String]
    
    var displayImageUrls: [String] {
        if !photos.isEmpty {
            return photos
        } else {
            return [imageURL]
        }
    }

    let address: String
    let phone: String
    let url: String
    let transactions: [String]
    let hours: [YelpOpenHours]?
    let isOpen: Bool
    var isFavorite: Bool = false
    var lastAccessDate: Date = Date()
}


extension CoffeeShop {
    static func ==(lhs: CoffeeShop, rhs: CoffeeShop) -> Bool {
        lhs.id == rhs.id
    }
}
