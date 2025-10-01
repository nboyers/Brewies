//
//  UserViewModel.swift
//  Brewies
//
//  Created by Noah Boyers on 7/6/23.
//

import Foundation
import SwiftUI

// Define a struct to hold your UserDefaults keys
struct UserKeys {
    static let isLoggedIn = "isLoggedIn"
    static let userID = "userID"
    static let firstName = "UserFirstName"
    static let lastName = "UserLastName"
    static let userStreakCount = "UserStreakCount"
    static let userStreakContentViewed = "UserStreakContentViewed"
    static let isPremium = "isPremium"

    // Computed properties for user-specific keys
    static func userCredits(_ userID: String) -> String { "UserCredits_\(userID)" }
}

class UserViewModel: ObservableObject {
    static let shared = UserViewModel()
    @Published var user: User
    @Published var profileImage: Image?
    
    init() {
        
        let isLoggedIn = UserDefaults.standard.bool(forKey: UserKeys.isLoggedIn)
        let userID = UserDefaults.standard.string(forKey: UserKeys.userID) ?? ""
        let key = isLoggedIn ? UserKeys.userCredits(userID) : UserKeys.userCredits("Guest")
        let credits = UserDefaults.standard.integer(forKey: key)
        
        let streakCount = UserDefaults.standard.integer(forKey: UserKeys.userStreakCount)
        let streakViewedDate = UserDefaults.standard.object(forKey: UserKeys.userStreakContentViewed) as? Date
        
        user = User(isLoggedIn: isLoggedIn, userID: userID, firstName: "", lastName: "", email: "", profileImage: nil, favorites: [], pastOrders: [], credits: credits, hasClaimedWeeklyReward: false, streakCount: streakCount, streakViewedDate: streakViewedDate, isPremium: UserDefaults.standard.bool(forKey: UserKeys.isPremium))
        
        loadUserDetails()
        loadFavorites()
    }
    
    func saveUserLoginStatus() {
        UserDefaults.standard.set(true, forKey: UserKeys.isLoggedIn)
        UserDefaults.standard.set(user.userID, forKey: UserKeys.userID)
        UserDefaults.standard.set(user.firstName, forKey: UserKeys.firstName)
        UserDefaults.standard.set(user.lastName, forKey: UserKeys.lastName)
    }
    
    func loadUserLoginStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: UserKeys.isLoggedIn)
    }
    
    func loadUserDetails() {
        let firstName = UserDefaults.standard.string(forKey: UserKeys.firstName) ?? ""
        let lastName = UserDefaults.standard.string(forKey: UserKeys.lastName) ?? ""
        user.firstName = firstName
        user.lastName = lastName
        user.isPremium = UserDefaults.standard.bool(forKey: UserKeys.isPremium)
    }
    
    func signOut() {
        user.firstName = ""
        user.lastName = ""
        user.isLoggedIn = false
        UserDefaults.standard.set(false, forKey: UserKeys.isLoggedIn)
        UserDefaults.standard.removeObject(forKey: UserKeys.userID)
    }
    
    func syncCredits(accountStatus: String) {
        switch accountStatus {
        case "login":
            let guestCredits = UserDefaults.standard.integer(forKey: UserKeys.userCredits("Guest"))
            UserDefaults.standard.set(guestCredits, forKey: UserKeys.userCredits(user.userID))
            DispatchQueue.main.async {
                self.user.credits = guestCredits
            }
            break
            
        case "signOut":
            let userCredits = UserDefaults.standard.integer(forKey: UserKeys.userCredits(user.userID))
            UserDefaults.standard.set(userCredits, forKey: UserKeys.userCredits("Guest"))
            DispatchQueue.main.async {
                self.user.credits = userCredits
            }
            break
            
        default:
            break
        }
    }
    
    func addOrder(order: Order) {
        user.pastOrders.append(order)
    }
    
    func addCredits(_ amount: Int) {
        DispatchQueue.main.async {
            let key = self.user.isLoggedIn ? UserKeys.userCredits(self.user.userID) : UserKeys.userCredits("Guest")
            self.user.credits += amount
            UserDefaults.standard.set(self.user.credits, forKey: key)
//            print("Credits After: \(self.user.credits)")
        }
    }

    
    func subtractCredits(_ amount: Int) {
        user.credits -= amount
        let key = user.isLoggedIn ? UserKeys.userCredits(user.userID) : UserKeys.userCredits("Guest")
        UserDefaults.standard.set(user.credits, forKey: key)
    }
    


    
    func addToFavorites(_ coffeeShop: BrewLocation) {
        // Check if user can add more favorites
        if canAddFavorite() {
            user.favorites.append(coffeeShop)
            saveFavorites()
        }
    }
    
    func canAddFavorite() -> Bool {
        return user.isPremium || user.favorites.count < 3
    }
    
    var favoritesLimit: Int {
        return user.isPremium ? Int.max : 3
    }
    
    func removeFromFavorites(_ coffeeShop: BrewLocation) {
        if let index = user.favorites.firstIndex(of: coffeeShop) {
            user.favorites.remove(at: index)
            saveFavorites()
        }
    }
    
    func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(user.favorites) {
            UserDefaults.standard.set(encoded, forKey: "UserFavorites")
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "UserFavorites"),
           let favorites = try? JSONDecoder().decode([BrewLocation].self, from: data) {
            user.favorites = favorites
        }
    }
    
    func setPremium(_ isPremium: Bool) {
        user.isPremium = isPremium
        UserDefaults.standard.set(isPremium, forKey: UserKeys.isPremium)
    }
    

    

    func deleteUserData() {
        // Remove user-related keys from UserDefaults
        UserDefaults.standard.removeObject(forKey: UserKeys.isLoggedIn)
        UserDefaults.standard.removeObject(forKey: UserKeys.userID)
        UserDefaults.standard.removeObject(forKey: UserKeys.firstName)
        UserDefaults.standard.removeObject(forKey: UserKeys.lastName)
        UserDefaults.standard.removeObject(forKey: UserKeys.userStreakCount)
        UserDefaults.standard.removeObject(forKey: UserKeys.userStreakContentViewed)
        UserDefaults.standard.removeObject(forKey: UserKeys.userCredits(user.userID))
        UserDefaults.standard.removeObject(forKey: "UserFavorites")
        
        // Reset in-memory user data
        user = User(isLoggedIn: false, userID: "", firstName: "", lastName: "", email: "", profileImage: nil, favorites: [], pastOrders: [], credits: 0, hasClaimedWeeklyReward: false, streakCount: 0, streakViewedDate: nil, isPremium: false)
    }
}
