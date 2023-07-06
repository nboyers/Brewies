//
//  UserViewModel.swift
//  Brewies
//
//  Created by Noah Boyers on 7/6/23.
//

import Foundation
import SwiftUI

class UserViewModel: ObservableObject {
    static let shared = UserViewModel()
    
    @Published var user: User
    @Published var profileImage: Image?
    
    
    init(user: User = User(isLoggedIn: false, userID: "", firstName: "", lastName: "", email: "", isSubscribed: false, profileImage: nil, favorites: [], pastOrders: [], credits: 0)) {
        self.user = user
        
        let key = user.isLoggedIn ? "UserCredits_\(user.userID)" : "UserCredits_Guest"
        if UserDefaults.standard.object(forKey: "isNewUser") == nil && user.isLoggedIn {
            self.user.credits = 1
            UserDefaults.standard.set(false, forKey: "isNewUser")
        } else {
            self.user.credits = UserDefaults.standard.integer(forKey: key)
        }
    }
    
    func saveUserLoginStatus() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
    }
    
    func loadUserLoginStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: "isLoggedIn")
    }
    
    func signOut() {
        self.user.firstName = ""
        self.user.lastName = ""
        self.user.isLoggedIn = false
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
    }
    
    func syncCredits() {
        let guestCredits = UserDefaults.standard.integer(forKey: "UserCredits_Guest")
        let userCredits = UserDefaults.standard.integer(forKey: "UserCredits_\(self.user.userID)")
        let mergedCredits = guestCredits + userCredits
        UserDefaults.standard.set(mergedCredits, forKey: "UserCredits_\(self.user.userID)")
        UserDefaults.standard.set(0, forKey: "UserCredits_Guest")
        self.user.credits = mergedCredits
    }
    
    func addOrder(order: Order) {
        self.user.pastOrders.append(order)
    }
    
    func addToFavorites(_ coffeeShop: CoffeeShop) {
        user.favorites.append(coffeeShop)
        // Persist the user's favorites to your storage
    }
    
    func removeFromFavorites(_ coffeeShop: CoffeeShop) {
        if let index = user.favorites.firstIndex(of: coffeeShop) {
            user.favorites.remove(at: index)
            // Persist the user's favorites to your storage
        }
    }
}
