//
//  BrewiesApp.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.
//

import SwiftUI
import GoogleMobileAds

@main
struct BrewiesApp: App {
    private var rewardAd = RewardAdController()
    let yelpParams = YelpSearchParams()
    let contentViewModel: ContentViewModel
    
    
    init() {
        self.contentViewModel = ContentViewModel(yelpParams: yelpParams)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(UserViewModel.shared)
                .environmentObject(yelpParams)
                .environmentObject(contentViewModel)
                .onAppear {
                    GADMobileAds.sharedInstance().start(completionHandler: nil)
                }
        }
    }
}

