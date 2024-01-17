//
//  SharedAlertViewModel.swift
//  Brewies
//
//  Created by Noah Boyers on 9/4/23.
//

import Foundation

@MainActor
class SharedAlertViewModel: NSObject, ObservableObject {
    @Published var currentAlertType: CustomAlertType? = nil
}

enum CustomAlertType {
    case insufficientCredits
    case maxFavoritesReached
    case notSubscribed
    case streakCount
    case notLoggedIn
    case tooSoon
    case showInstructions
    case streakReward
    case showNotEnoughStreakAlert
    case noAdsAvailableAlert
    case earnCredits
    case missingSearchCredits
}
