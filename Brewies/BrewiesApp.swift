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
import AppTrackingTransparency

@main
struct BrewiesApp: App {
    private let rewardAdController: RewardAdController
    private let contentViewModel: ContentViewModel
    private let sharedViewModel = SharedViewModel()
    @StateObject private var locationManager = LocationManager() // Use @StateObject for LocationManager
    let storeKitManager = StoreKitManager()
    @StateObject private var selectedCoffeeShop = SelectedCoffeeShop()
    @StateObject private var attManager = ATTManager()

    init() {
        self.contentViewModel = ContentViewModel()
        rewardAdController = RewardAdController()
        
        // Request ATT permission immediately on app launch
        DispatchQueue.main.async {
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization { status in
                    DispatchQueue.main.async {
                        MobileAds.shared.start { _ in }
                    }
                }
            } else {
                MobileAds.shared.start { _ in }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(rewardAdController)
                .environmentObject(UserViewModel.shared)
                .environmentObject(selectedCoffeeShop)
                .environmentObject(contentViewModel)
                .environmentObject(SharedAlertViewModel())
                .environmentObject(sharedViewModel)
                .environmentObject(storeKitManager)
                .environmentObject(locationManager) // Pass locationManager to environment
                .environmentObject(attManager)
                .onAppear {
                    _ = storeKitManager.listenForTransactions()
                }
        }
    }
}
