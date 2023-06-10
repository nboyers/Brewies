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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                GADMobileAds.sharedInstance().start(completionHandler: nil)
                  
            }
        }
    }
}
