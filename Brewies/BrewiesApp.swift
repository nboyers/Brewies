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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(UserViewModel.shared)
                .onAppear {
                GADMobileAds.sharedInstance().start(completionHandler: nil)
            }
        }
    }
}
