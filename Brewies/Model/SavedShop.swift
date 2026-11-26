//
//  SavedShop.swift
//  Brewies
//
//  A shop the user wants to try or has marked as a favorite.
//

import Foundation
import SwiftData

@Model
final class SavedShop {
    var shopID: String = ""
    var name: String = ""
    var categoryRaw: String = "coffee"
    var latitude: Double = 0
    var longitude: Double = 0
    var address: String = ""
    var savedAt: Date = Date()
    var wantsToTry: Bool = false
    var isFavorite: Bool = false

    init(shop: Shop) {
        self.shopID = shop.id
        self.name = shop.name
        self.categoryRaw = shop.category.rawValue
        self.latitude = shop.latitude
        self.longitude = shop.longitude
        self.address = shop.address ?? ""
    }
}
