//
//  BrewiesApp.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.
//

import SwiftUI
import SwiftData

@main
struct BrewiesApp: App {
    @State private var location = LocationService()
    @State private var store = StoreManager()
    @State private var container = DataStore.makeContainer(sync: StoreManager.cachedIsPro)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(location)
                .environment(store)
                .onChange(of: store.isPro) { _, isPro in
                    // Switch on iCloud sync when Pro starts, and off again if it lapses.
                    container = DataStore.makeContainer(sync: isPro)
                }
        }
        .modelContainer(container)
    }
}
