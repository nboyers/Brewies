//
//  User.swift
//  Brewies
//
//  Created by Noah Boyers on 6/9/23.
//

import Foundation
import SwiftUI

class User: ObservableObject {
    static let shared = User()

    @Published var isLoggedIn: Bool
    @Published var userID: String
    @Published var firstName: String
    @Published var lastName: String
    @Published var email: String
    @Published var profileImage: Image?
    @Published var favorites: [CoffeeShop] = []
    @Published var pastOrders: [Order] = []
    @Published var credits: Int {
           didSet {
               UserDefaults.standard.set(self.credits, forKey: "UserCredits")
           }
       }
    
    @Published var isSubscribed: Bool  
    
    init(isLoggedIn: Bool = false, userID: String = "", firstName: String = "", lastName: String = "", email: String = "", profileImage: Image? = nil, isSubscribed: Bool = false) {
        self.isLoggedIn = isLoggedIn
        self.userID = userID
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.profileImage = profileImage
        self.credits = UserDefaults.standard.integer(forKey: "UserCredits")
        self.isSubscribed = isSubscribed // And this line
    }
}


struct Order: Identifiable, Codable {
    let id: String
    let coffeeShop: CoffeeShop
    let date: Date
    let amount: Double
    let items: [String] // Replace this with your specific order item model
}
