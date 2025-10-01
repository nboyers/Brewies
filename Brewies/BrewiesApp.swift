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
    private let sharedViewModel = SharedViewModel()
    @StateObject private var locationManager = LocationManager() // Use @StateObject for LocationManager
    let storeKitManager = StoreKitManager()
    @StateObject private var selectedCoffeeShop = SelectedCoffeeShop()

    init() {
        MobileAds.shared.start { status in }

        self.contentViewModel = ContentViewModel()
        rewardAdController = RewardAdController()
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
                .onAppear {
                    _ = storeKitManager.listenForTransactions()
                }
        }
    }
}
