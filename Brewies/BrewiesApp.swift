//
//  BrewiesApp.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.
//

import SwiftUI
import GoogleMobileAds
import StoreKit

@main
struct BrewiesApp: App {
    private let rewardAd = RewardAdController()
    private let yelpParams = YelpSearchParams()
    private let contentViewModel: ContentViewModel
    private let sharedViewModel = SharedViewModel()
    private let locationManager = LocationManager()

    @StateObject private var selectedCoffeeShop = SelectedCoffeeShop()
    
    init() {
   self.contentViewModel = ContentViewModel(yelpParams: yelpParams)
        
        // Perform any setup that doesn't require the UI to be loaded.
        DispatchQueue.global(qos: .background).async {
            GADMobileAds.sharedInstance().start(completionHandler: nil)
//            self.contentViewModel = ContentViewModel(yelpParams: yelpParams)
        }
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
        
        }
    }
}
