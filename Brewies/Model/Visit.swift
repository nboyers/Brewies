//
//  Visit.swift
//  Brewies
//
//  One logged visit to a shop. Every property has a default so the model stays
//  compatible with CloudKit sync.
//

import Foundation
import SwiftData

@Model
final class Visit {
    var shopID: String = ""
    var shopName: String = ""
    var categoryRaw: String = "coffee"
    var latitude: Double = 0
    var longitude: Double = 0
    var address: String = ""
    var visitedAt: Date = Date()
    /// 1...5, or 0 when the visit wasn't rated.
    var rating: Int = 0
    var drink: String = ""
    var notes: String = ""
    @Attribute(.externalStorage) var photoData: Data?

    init(shop: Shop, visitedAt: Date = Date(), rating: Int = 0, drink: String = "", notes: String = "", photoData: Data? = nil) {
        self.shopID = shop.id
        self.shopName = shop.name
        self.categoryRaw = shop.category.rawValue
        self.latitude = shop.latitude
        self.longitude = shop.longitude
        self.address = shop.address ?? ""
        self.visitedAt = visitedAt
        self.rating = rating
        self.drink = drink
        self.notes = notes
        self.photoData = photoData
    }
}
