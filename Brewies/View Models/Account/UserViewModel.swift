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
    
    init() {
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        let userID = UserDefaults.standard.string(forKey: "userID") ?? ""
        let key = isLoggedIn ? "UserCredits_\(userID)" : "UserCredits_Guest"
        let credits = UserDefaults.standard.integer(forKey: key)
        
        self.user = User(isLoggedIn: isLoggedIn, userID: userID, firstName: "", lastName: "", email: "", isSubscribed: false, profileImage: nil, favorites: [], pastOrders: [], credits: credits)
        loadUserDetails()
    }



    func saveUserLoginStatus() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(user.userID, forKey: "userID")
        UserDefaults.standard.set(user.isSubscribed, forKey: "isSubscribed") // Save isSubscribed status to UserDefaults
        UserDefaults.standard.set(user.firstName, forKey: "UserFirstName")
        UserDefaults.standard.set(user.lastName, forKey: "UserLastName")
    }

    func loadUserLoginStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: "isLoggedIn")
    }
    
    
    func loadUserDetails() {
        let firstName = UserDefaults.standard.string(forKey: "UserFirstName") ?? ""
        let lastName = UserDefaults.standard.string(forKey: "UserLastName") ?? ""
        user.isSubscribed = UserDefaults.standard.bool(forKey: "isSubscribed")
        user.firstName = firstName
        user.lastName = lastName
    }

    
    func signOut() {
        self.user.firstName = ""
        self.user.lastName = ""
        self.user.isLoggedIn = false
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userID")
    }

    func syncCredits() {
        let guestCredits = UserDefaults.standard.integer(forKey: "UserCredits_Guest")
        UserDefaults.standard.set(0, forKey: "UserCredits_Guest") // Reset guest credits immediately
        
        let userCredits = UserDefaults.standard.integer(forKey: "UserCredits_\(self.user.userID)")
        let mergedCredits = guestCredits + userCredits
        
        UserDefaults.standard.set(mergedCredits, forKey: "UserCredits_\(self.user.userID)")
        self.user.credits = mergedCredits

    }
    
    func addOrder(order: Order) {
        self.user.pastOrders.append(order)
    }
    
    func addCredits(_ amount: Int = 1) {
        self.user.credits += amount
        let key = user.isLoggedIn ? "UserCredits_\(user.userID)" : "UserCredits_Guest"
        UserDefaults.standard.set(self.user.credits, forKey: key)  
        // Sync the credits
        self.syncCredits()
        
        // Print statement to log when and how many credits are being added
        print("Added 1 credit. Total credits: \(self.user.credits)")
    }


    
    func subtractCredits(_ amount: Int) {
        self.user.credits -= amount
        let key = user.isLoggedIn ? "UserCredits_\(self.user.userID)" : "UserCredits_Guest"
        UserDefaults.standard.set(self.user.credits, forKey: key)
    }
    
    func subscribe() {
        // Subscription logic here...
        // Once the subscription is successful:
        self.user.isSubscribed = true
        UserDefaults.standard.set(true, forKey: "isSubscribed")
    }

    func unsubscribe() {
        // Unsubscription logic here...
        // Once the unsubscription is successful:
        self.user.isSubscribed = false
        UserDefaults.standard.set(false, forKey: "isSubscribed")
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
