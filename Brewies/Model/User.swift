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
    @Published var isSubscribed: Bool
    @Published var profileImage: Image?
    @Published var favorites: [CoffeeShop] = []
    @Published var pastOrders: [Order] = []
    @Published var credits: Int {
        didSet {
            // We are persisting credits differently based on whether the user is logged in.
            let key = isLoggedIn ? "UserCredits_\(userID)" : "UserCredits_Guest"
            UserDefaults.standard.set(self.credits, forKey: key)
        }
    }
    
    
    init(isLoggedIn: Bool = false, userID: String = "", firstName: String = "", lastName: String = "", email: String = "", profileImage: Image? = nil, isSubscribed: Bool = false) {
        self.isLoggedIn = isLoggedIn
        self.userID = userID
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.profileImage = profileImage
        
        let key = isLoggedIn ? "UserCredits_\(userID)" : "UserCredits_Guest"
        // Check if the user is new and logged in
        if UserDefaults.standard.object(forKey: "isNewUser") == nil && isLoggedIn {
            // The user is new and logged in, so give them 1 credit
            self.credits = 1
            UserDefaults.standard.set(false, forKey: "isNewUser")
        } else {
            // The user is not new or not logged in, so get their credits from UserDefaults
            self.credits = UserDefaults.standard.integer(forKey: key)
        }
        
        self.isSubscribed = isSubscribed
    }
    
    
    func saveUserLoginStatus() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
    }
    
    func loadUserLoginStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: "isLoggedIn")
    }
    
    func signOut() {
        // Reset the user's data
        self.firstName = ""
        self.lastName = ""
        self.isLoggedIn = false
        // Also update UserDefaults
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        
    }
    
    func syncCredits() {
        let guestCredits = UserDefaults.standard.integer(forKey: "UserCredits_Guest")
        let userCredits = UserDefaults.standard.integer(forKey: "UserCredits_\(userID)")
        let mergedCredits = guestCredits + userCredits
        UserDefaults.standard.set(mergedCredits, forKey: "UserCredits_\(userID)")
        UserDefaults.standard.set(0, forKey: "UserCredits_Guest")  // Reset guest credits
        self.credits = mergedCredits  // Update the credits property in the User object
    }
    
}


//This will be used in a later date 
struct Order: Identifiable, Codable {
    let id: String
    let coffeeShop: CoffeeShop
    let date: Date
    let amount: Double
    let items: [String] // Replace this with your specific order item model
}
