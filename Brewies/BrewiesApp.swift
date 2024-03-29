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
    private let rewardAdController : RewardAdController
    private let yelpParams = YelpSearchParams()
    private let contentViewModel: ContentViewModel
    private let sharedViewModel = SharedViewModel()
    private let locationManager = LocationManager()
    let storeKitManager = StoreKitManager()
    @StateObject private var selectedCoffeeShop = SelectedCoffeeShop()
    
    init() {
        self.contentViewModel = ContentViewModel(yelpParams: yelpParams)
        rewardAdController = RewardAdController()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(rewardAdController)
                .environmentObject(UserViewModel.shared)
                .environmentObject(yelpParams)
                .environmentObject(selectedCoffeeShop)
                .environmentObject(contentViewModel)
                .environmentObject(SharedAlertViewModel())
                .environmentObject(sharedViewModel)
                .environmentObject(storeKitManager)
                .onAppear {
                    _=storeKitManager.listenForTransactions()
                }
            
            
        }
    }
}
