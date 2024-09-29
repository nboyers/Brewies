//
//  ContentViewModel.swift
//  Brewies
//
//  Created by Noah Boyers on 6/29/23.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

class ContentViewModel: ObservableObject {
    @Published var brewLocations: [BrewLocation] = []
    @Published var selectedBrewLocation: BrewLocation?
    @Published var showAlert = false
    @Published var showBrewPreview = false
    @Published var searchQuery: String = ""
    @Published var showNoBrewLocationsAlert = false
    @Published var showNoAdsAvailableAlert = false
    @Published var showNoCreditsAlert = false
    @Published var adsWatched = 0
    @Published var fetchedFromCache = false

    @Published var userViewModel = UserViewModel.shared
    @Published var apiKeysViewModel = APIKeysViewModel.shared

    private var rewardAdController = RewardAdController()
    private var googlePlacesAPI = GooglePlacesAPI(googlePlacesParams: GooglePlacesSearchParams()) // Initialize Google Places API

    // Define the available brew types
    enum BrewType: String {
        case coffee = "Coffee"
        case alcohol = "Alcohol"
    }

    // State to control the selected brew type
    @Published var selectedBrewType: BrewType = .coffee

    init() {
        rewardAdController.onUserDidEarnReward = { [weak self] in
            DispatchQueue.main.async {
                self?.userViewModel.addCredits(1)
                self?.userViewModel.syncCredits(accountStatus: "")
            }
        }
        clearOldCache()
    }

    // Main method to fetch either coffee shops or alcohol venues using Google Places API
    func fetchBrewies(locationManager: LocationManager, visibleRegionCenter: CLLocationCoordinate2D?, brewType: String = "cafe", term: String = "coffee") {
        deductUserCredit()

        guard let centerCoordinate = visibleRegionCenter ?? locationManager.userLocation else {
            DispatchQueue.main.async {
                self.showAlert = true
            }
            return
        }

        // Using async/await to fetch the API keys
        Task {
            do {
                guard let apiKey = await apiKeysViewModel.fetchAPIKeys()?.GOOGLE_PLACES_API else {
                    DispatchQueue.main.async {
                        self.showAlert = true
                    }
                    return
                }

                // Use the Google Places API to fetch nearby locations asynchronously
                let shops = try await self.googlePlacesAPI.fetchNearbyPlaces(
                    apiKey: apiKey,
                    latitude: centerCoordinate.latitude,
                    longitude: centerCoordinate.longitude,
                    query: term
                )

                DispatchQueue.main.async {
                    self.processBrewLocations(brewLocations: shops)
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert = true
                }
                print("Error fetching brew locations: \(error)")
            }
        }
    }

    private func processBrewLocations(brewLocations: [BrewLocation]) {
        self.brewLocations = brewLocations
        self.selectedBrewLocation = brewLocations.first
        self.showBrewPreview = !brewLocations.isEmpty
    }

    private func saveToCache(brewLocations: [BrewLocation], forKey key: String) {
        let data = try? JSONEncoder().encode(brewLocations)
        UserDefaults.standard.set(data, forKey: key)
        UserDefaults.standard.set(Date(), forKey: "\(key)-date")
    }

    private func clearOldCache() {
        let userDefaults = UserDefaults.standard
        let cacheKeys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasSuffix("-date") }
        let currentDate = Date()
        let expirationInterval: TimeInterval = 86400 // 24 hours

        // Prepare a copy of data before using it inside the async closure
        let cacheData = cacheKeys.compactMap { key -> (key: String, date: Date)? in
            if let cacheDate = userDefaults.object(forKey: key) as? Date {
                return (key: key, date: cacheDate)
            }
            return nil
        }

        // Perform the cleanup in a background thread
        DispatchQueue.global(qos: .background).async {
            for cacheItem in cacheData {
                if currentDate.timeIntervalSince(cacheItem.date) > expirationInterval {
                    let dataKey = String(cacheItem.key.dropLast("-date".count))
                    
                    // Remove from UserDefaults in the main thread to avoid thread safety issues
                    Task {
                        userDefaults.removeObject(forKey: dataKey)
                        userDefaults.removeObject(forKey: cacheItem.key)
                    }
                }
            }
        }
    }

    private func retrieveFromCache(forKey key: String) -> [BrewLocation]? {
        if let data = UserDefaults.standard.data(forKey: key) {
            return try? JSONDecoder().decode([BrewLocation].self, from: data)
        }
        return nil
    }

    func handleRewardAd(reward: String) {
        DispatchQueue.main.async { [self] in
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let viewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                rewardAdController.present(from: viewController, rewardType: reward)
            }
        }
    }

    func deductUserCredit() {
        DispatchQueue.main.async { [self] in
            if userViewModel.user.credits > 0 {
                userViewModel.subtractCredits(1)
            } else {
                showNoCreditsAlert = true
            }
        }
    }
}
