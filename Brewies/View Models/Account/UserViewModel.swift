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
    static let isSubscribed = "isSubscribed"
    static let firstName = "UserFirstName"
    static let lastName = "UserLastName"
    static let userStreakCount = "UserStreakCount"
    static let userStreakContentViewed = "UserStreakContentViewed"

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
        
        user = User(isLoggedIn: isLoggedIn, userID: userID, firstName: "", lastName: "", email: "", isSubscribed: false, profileImage: nil, favorites: [], pastOrders: [], credits: credits, streakCount: streakCount, streakViewedDate: streakViewedDate)
        
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
            user.credits = guestCredits
            
            
        case "signOut":
            let userCredits = UserDefaults.standard.integer(forKey: UserKeys.userCredits(user.userID))
            UserDefaults.standard.set(userCredits, forKey: UserKeys.userCredits("Guest"))
            user.credits = userCredits
            
            
        default:
            break
        }
    }
    
    func addOrder(order: Order) {
        user.pastOrders.append(order)
    }
    
    func addCredits(_ amount: Int = 1) {
        user.credits += amount
        let key = user.isLoggedIn ? UserKeys.userCredits(user.userID) : UserKeys.userCredits("Guest")
        UserDefaults.standard.set(user.credits, forKey: key)
    }
    
    func subtractCredits(_ amount: Int) {
        user.credits -= amount
        let key = user.isLoggedIn ? UserKeys.userCredits(user.userID) : UserKeys.userCredits("Guest")
        UserDefaults.standard.set(user.credits, forKey: key)
    }
    
    func subscribe() {
        // Subscription logic here...
        user.isSubscribed = true
        UserDefaults.standard.set(true, forKey: UserKeys.isSubscribed)
    }
    
    func unsubscribe() {
        // Unsubscription logic here...
        user.isSubscribed = false
        UserDefaults.standard.set(false, forKey: UserKeys.isSubscribed)
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
    
    func saveStreakData() {
        let lastWatchedDate = Date()
        let elapsedHours = user.streakViewedDate != nil ? Calendar.current.dateComponents([.hour], from: user.streakViewedDate!, to: lastWatchedDate).hour ?? 0 : 28
        let newStreakCount = (elapsedHours <= 28 && elapsedHours >= 24) ? user.streakCount + 1 : 0
        
        user.streakCount = newStreakCount
        user.streakViewedDate = lastWatchedDate
        
        user.credits += 5
        let key = user.isLoggedIn ? UserKeys.userCredits(user.userID) : UserKeys.userCredits("Guest")
        UserDefaults.standard.set(user.credits, forKey: key)
        
        UserDefaults.standard.set(user.streakCount, forKey: UserKeys.userStreakCount)
        UserDefaults.standard.set(user.streakViewedDate, forKey: UserKeys.userStreakContentViewed)
    }
    
    func timeLeft() -> String {
        guard let lastDate = user.streakViewedDate else {
            print("DEBUG: lastDate is nil")
            // You could return a default value or handle the error in some way
            return "No date available"
        }

        let elapsedHours = Calendar.current.dateComponents([.hour], from: lastDate, to: Date()).hour ?? 0
        let remainingHours = 24 - elapsedHours

        guard let nextCheckInDate = Calendar.current.date(byAdding: .hour, value: remainingHours, to: lastDate) else {
            print("DEBUG: Unable to compute nextCheckInDate")
            return "Error computing next check-in time"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a, EEEE, MMM d"
        formatter.timeZone = TimeZone.current

        let formattedString = formatter.string(from: nextCheckInDate)

        return formattedString
        
    }
//    
//    func loadStreakData() -> (streakCount: Int, lastWatchedDate: Date?) {
//        let streakCount = user.streakCount
//        let lastWatchedDate = user.streakViewedDate
//        
//        print("DEBUG: Load \(streakCount), \(String(describing: lastWatchedDate))")
//        return (streakCount, lastWatchedDate)
//    }
}
