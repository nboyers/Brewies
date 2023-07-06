//
//  User.swift
//  Brewies
//
//  Created by Noah Boyers on 6/9/23.
//

import Foundation
import SwiftUI

struct User {
    var isLoggedIn: Bool
    var userID: String
    var firstName: String
    var lastName: String
    var email: String
    var isSubscribed: Bool
    var profileImage: Image?
    var favorites: [CoffeeShop]
    var pastOrders: [Order]
    var credits: Int
}


//This will be used in a later date 
struct Order: Identifiable, Codable {
    let id: String
    let coffeeShop: CoffeeShop
    let date: Date
    let amount: Double
    let items: [String] // Replace this with your specific order item model
}
