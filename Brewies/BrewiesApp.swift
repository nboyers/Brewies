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
    private var rewardAd = RewardAdController()
    let yelpParams = YelpSearchParams()
    let contentViewModel: ContentViewModel
    let sharedViewModel = SharedViewModel()
    let locationManager = LocationManager()

    @StateObject var selectedCoffeeShop = SelectedCoffeeShop()
    
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


