//
//  PremiumFeatures.swift
//  Brewies
//
//  Enhanced monetization model
//

import Foundation

struct PremiumFeatures {
    static let dailySearchLimit = 5
    
    enum Feature: String, CaseIterable {
        case unlimitedSearches = "unlimited_searches"
        case advancedFilters = "advanced_filters"
        case businessDetails = "business_details"
        case favoritesCollections = "favorites_collections"
        case offlineMaps = "offline_maps"
        case prioritySupport = "priority_support"
        
        var title: String {
            switch self {
            case .unlimitedSearches: return "Unlimited Searches"
            case .advancedFilters: return "Advanced Filters"
            case .businessDetails: return "Business Intelligence"
            case .favoritesCollections: return "Favorites Collections"
            case .offlineMaps: return "Offline Maps"
            case .prioritySupport: return "Priority Support"
            }
        }
        
        var description: String {
            switch self {
            case .unlimitedSearches: return "Search as much as you want"
            case .advancedFilters: return "Filter by cuisine, amenities, and more"
            case .businessDetails: return "Hours, phone, website, and reviews"
            case .favoritesCollections: return "Organize places into custom lists"
            case .offlineMaps: return "Download areas for offline use"
            case .prioritySupport: return "Get help when you need it"
            }
        }
    }
    
    static func hasAccess(to feature: Feature, isSubscribed: Bool) -> Bool {
        switch feature {
        case .unlimitedSearches, .advancedFilters, .businessDetails, 
             .favoritesCollections, .offlineMaps, .prioritySupport:
            return isSubscribed
        }
    }
}