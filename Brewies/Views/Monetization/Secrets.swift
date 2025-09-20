//
//  Secrets.swift
//  Brewies
//
//  Auto-generated stub to resolve missing Secrets reference.
//  Replace placeholder values with your real keys or load from Info.plist.
//

import Foundation

/// Central place for API keys and secrets.
///
/// IMPORTANT: Do not commit real secrets to source control. Prefer loading
/// from Info.plist, environment configuration, or encrypted storage.
struct Secrets {
    /// AdMob Banner Ad Unit ID.
    /// TODO: Replace with your real Ad Unit ID or read from Info.plist.
    static let BANNER_AD_KEY: String = {
        // Attempt to read from Info.plist key `GADBannerAdUnitID` if present.
        if let id = Bundle.main.object(forInfoDictionaryKey: "GADBannerAdUnitID") as? String, !id.isEmpty {
            return id
        }
        // Fallback to Google's sample/test ad unit ID so development builds don't crash.
        // Replace this with your production unit ID before release.
        return "ca-app-pub-3940256099942544/2934735716"
    }()
    
    /// Google Places API Key.
    /// TODO: Replace with your real API key or read from Info.plist.
    static let PLACES_API: String = {
        // Attempt to read from Info.plist key `GooglePlacesAPIKey` if present.
        if let key = Bundle.main.object(forInfoDictionaryKey: "GooglePlacesAPIKey") as? String, !key.isEmpty {
            return key
        }
        // Fallback - replace with your actual API key
        return "YOUR_GOOGLE_PLACES_API_KEY_HERE"
    }()
}
