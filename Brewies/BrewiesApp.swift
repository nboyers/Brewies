//
//  BrewiesApp.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.
//

import SwiftUI
import GoogleMobileAds
import StoreKit
import GooglePlaces

@main
struct BrewiesApp: App {
    private let rewardAdController: RewardAdController
    private let contentViewModel: ContentViewModel
    @StateObject private var locationManager = LocationManager() // Use @StateObject for LocationManager
    let storeKitManager = StoreKitManager()
    @StateObject private var selectedCoffeeShop = SelectedCoffeeShop()

    init() {
        GADMobileAds.sharedInstance().start { status in
            print("Google Mobile Ads SDK initialized with status: \(status)")
        }

        self.contentViewModel = ContentViewModel()
        rewardAdController = RewardAdController()
        GMSPlacesClient.provideAPIKey(Secrets.PLACES_API)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(rewardAdController)
                .environmentObject(UserViewModel.shared)
                .environmentObject(selectedCoffeeShop)
                .environmentObject(contentViewModel)
    
                .environmentObject(storeKitManager)
                .environmentObject(locationManager) // Pass locationManager to environment
                .onAppear {
                    _ = storeKitManager.listenForTransactions()
                }
        }
    }
}
