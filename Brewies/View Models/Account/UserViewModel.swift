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
        
        // Load streakCount and streakViewedDate from UserDefaults
        let streakCountKey = "UserStreakCount_\(userID)"
        let streakViewedDateKey = "UserStreakContentViewed_\(userID)"
        let streakCount = UserDefaults.standard.integer(forKey: streakCountKey)
        let streakViewedDate = UserDefaults.standard.object(forKey: streakViewedDateKey) as? Date
        print("Retrieved streakCount: \(streakCount), lastWatchedDate: \(String(describing: streakViewedDate))")

        user = User(isLoggedIn: isLoggedIn, userID: userID, firstName: "", lastName: "", email: "", isSubscribed: false, profileImage: nil, favorites: [], pastOrders: [], credits: credits, streakCount: streakCount, streakViewedDate: streakViewedDate)
        
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
        user.firstName = ""
        user.lastName = ""
        user.isLoggedIn = false
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userID")
    }

    func syncCredits(accountStatus: String) {
        
        switch accountStatus {
        case "login":
            let guestCredits = UserDefaults.standard.integer(forKey: "UserCredits_Guest")
            UserDefaults.standard.set(guestCredits, forKey: "UserCredits_\(user.userID)")
            user.credits = guestCredits
            
        case "signOut":
            let userCredits = UserDefaults.standard.integer(forKey: "UserCredits_\(user.userID)")
            UserDefaults.standard.set(userCredits, forKey: "UserCredits_Guest")
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
        let key = user.isLoggedIn ? "UserCredits_\(user.userID)" : "UserCredits_Guest"
        UserDefaults.standard.set(user.credits, forKey: key)
        
        // Print statement to log when and how many credits are being added
        print("Added 1 credit. Total credits: \(user.credits)")
    }


    
    func subtractCredits(_ amount: Int) {
        user.credits -= amount
        let key = user.isLoggedIn ? "UserCredits_\(user.userID)" : "UserCredits_Guest"
        UserDefaults.standard.set(user.credits, forKey: key)
    }
    
    func subscribe() {
        // Subscription logic here...
        // Once the subscription is successful:
        user.isSubscribed = true
        UserDefaults.standard.set(true, forKey: "isSubscribed")
    }

    func unsubscribe() {
        // Unsubscription logic here...
        // Once the unsubscription is successful:
        user.isSubscribed = false
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
    
    func saveStreakData() {

        // Ensure that the user is logged in and userID is not empty
        guard !user.userID.isEmpty else {
            print("DEBUG: ERROR! userID is empty.")
            return
        }

        // Use the current date and time as the lastWatchedDate
        let lastWatchedDate = Date()

        // Determine the number of hours since the last check-in
        let elapsedHours = user.streakViewedDate != nil ? Calendar.current.dateComponents([.hour], from: user.streakViewedDate!, to: lastWatchedDate).hour ?? 0 : 28

        // If it's been 28 hours or less since the last check-in, increment the streak count.
        // If it's been more than 28 hours, reset the streak count to 0.
        // Gave a buffer of 4 hrs to the users
        let newStreakCount = (elapsedHours <= 28) ? user.streakCount + 1 : 0

        // Save the updated streak data
        let streakCountKey = "UserStreakCount_\(user.userID)"
        let lastWatchedDateKey = "UserStreakContentViewed_\(user.userID)"
        UserDefaults.standard.set(newStreakCount, forKey: streakCountKey)
        UserDefaults.standard.set(lastWatchedDate, forKey: lastWatchedDateKey)
        user.streakCount = newStreakCount  // Update User model
        user.streakViewedDate = lastWatchedDate

        // Check if the data was saved correctly
        if UserDefaults.standard.integer(forKey: streakCountKey) != newStreakCount ||
            UserDefaults.standard.object(forKey: lastWatchedDateKey) as? Date != lastWatchedDate {
            print("DEBUG: ERROR! Failed to save streak data to UserDefaults.")
        } else {
            print("DEBUG: Successfully saved streak data.")
        }
    }


    func loadStreakData() -> (streakCount: Int, lastWatchedDate: Date?) {
        let streakCount = UserDefaults.standard.integer(forKey: "UserStreakCount_\(user.userID)")  // Include userID in key
        let lastWatchedDate = UserDefaults.standard.object(forKey: "UserStreakContentViewed_\(user.userID)") as? Date  // Include userID in key

        return (streakCount, lastWatchedDate)
    }

}
