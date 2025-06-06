//
//  UserViewModel.swift
//  Brewies
//
//  Created by Noah Boyers on 7/6/23.
//

import Foundation
import SwiftUI


enum SubscriptionTier: String {
    case monthly = "Monthly"
    case semiYearly = "SemiYearly"
    case yearly = "Yearly"
    case none = "None"
}


// Define a struct to hold your UserDefaults keys
struct UserKeys {
    static let isLoggedIn = "isLoggedIn"
    static let userID = "userID"
    static let isSubscribed = "isSubscribed"
    static let firstName = "UserFirstName"
    static let lastName = "UserLastName"
    static let userStreakCount = "UserStreakCount"
    static let userStreakContentViewed = "UserStreakContentViewed"
    static let subscriptionTier = "SubscriptionTier"

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
        
        user = User(isLoggedIn: isLoggedIn, userID: userID, firstName: "", lastName: "", email: "", isSubscribed: false, profileImage: nil, favorites: [], pastOrders: [], credits: credits, hasClaimedWeeklyReward: false, streakCount: streakCount, streakViewedDate: streakViewedDate)
        
        loadUserDetails()
    }
    
    func saveUserLoginStatus() {
        UserDefaults.standard.set(true, forKey: UserKeys.isLoggedIn)
        UserDefaults.standard.set(user.userID, forKey: UserKeys.userID)
        UserDefaults.standard.set(user.isSubscribed, forKey: UserKeys.isSubscribed)
        UserDefaults.standard.set(user.firstName, forKey: UserKeys.firstName)
        UserDefaults.standard.set(user.lastName, forKey: UserKeys.lastName)
    }
    
    func loadUserLoginStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: UserKeys.isLoggedIn)
    }
    
    func loadUserDetails() {
        let firstName = UserDefaults.standard.string(forKey: UserKeys.firstName) ?? ""
        let lastName = UserDefaults.standard.string(forKey: UserKeys.lastName) ?? ""
        user.isSubscribed = UserDefaults.standard.bool(forKey: UserKeys.isSubscribed)
        user.firstName = firstName
        user.lastName = lastName
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
    
    func subscribe(tier: SubscriptionTier) {
        user.isSubscribed = true
        user.subscriptionTier = tier
        UserDefaults.standard.set(true, forKey: UserKeys.isSubscribed)
        UserDefaults.standard.set(tier.rawValue, forKey: UserKeys.subscriptionTier)
    }

    func unsubscribe() {
        user.isSubscribed = false
        user.subscriptionTier = .none
        UserDefaults.standard.set(false, forKey: UserKeys.isSubscribed)
        UserDefaults.standard.set(SubscriptionTier.none.rawValue, forKey: UserKeys.subscriptionTier)
    }

    
    func addToFavorites(_ coffeeShop: BrewLocation) {
        user.favorites.append(coffeeShop)
        // Persist the user's favorites to your storage
    }
    
    func removeFromFavorites(_ coffeeShop: BrewLocation) {
        if let index = user.favorites.firstIndex(of: coffeeShop) {
            user.favorites.remove(at: index)
            // Persist the user's favorites to your storage
        }
    }
    

    

    func deleteUserData() {
        // Remove user-related keys from UserDefaults
        UserDefaults.standard.removeObject(forKey: UserKeys.isLoggedIn)
        UserDefaults.standard.removeObject(forKey: UserKeys.userID)
        UserDefaults.standard.removeObject(forKey: UserKeys.isSubscribed)
        UserDefaults.standard.removeObject(forKey: UserKeys.firstName)
        UserDefaults.standard.removeObject(forKey: UserKeys.lastName)
        UserDefaults.standard.removeObject(forKey: UserKeys.userStreakCount)
        UserDefaults.standard.removeObject(forKey: UserKeys.userStreakContentViewed)
        UserDefaults.standard.removeObject(forKey: UserKeys.userCredits(user.userID))
        
        // Reset in-memory user data
        user = User(isLoggedIn: false, userID: "", firstName: "", lastName: "", email: "", isSubscribed: false, profileImage: nil, favorites: [], pastOrders: [], credits: 0, hasClaimedWeeklyReward: false, streakCount: 0, streakViewedDate: nil)
    }    
}
