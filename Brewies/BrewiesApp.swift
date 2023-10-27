//
//  BrewiesApp.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.
//

import SwiftUI
import GoogleMobileAds
import StoreKit
import UIKit  // Import UIKit for UIApplicationDelegate

// Create a class that conforms to UIApplicationDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationDidEnterBackground(_ application: UIApplication) {
        UserViewModel.shared.saveStreakData()
    }
}

@main
struct BrewiesApp: App {
    // Use the UIApplicationDelegateAdaptor property wrapper to provide the AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    private let rewardAd = RewardAdController()
    private let yelpParams = YelpSearchParams()
    private let contentViewModel: ContentViewModel
    private let sharedViewModel = SharedViewModel()
    private let locationManager = LocationManager()

    @StateObject private var selectedCoffeeShop = SelectedCoffeeShop()
    
    init() {
        self.contentViewModel = ContentViewModel(yelpParams: yelpParams)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(UserViewModel.shared)
                .environmentObject(yelpParams)
                .environmentObject(selectedCoffeeShop)
                .environmentObject(contentViewModel)
                .environmentObject(SharedAlertViewModel())
                .environmentObject(sharedViewModel)
                .onAppear {
                    GADMobileAds.sharedInstance().start(completionHandler: nil)
                }
        }
    }
}
