//
//  RewardAdController.swift
//  Brewies
//
//  Created by Noah Boyers on 6/9/23.
//


import Foundation
import GoogleMobileAds
import GoogleMobileAdsTarget
import AppTrackingTransparency
import AdSupport
import UIKit

class RewardAdController: UIViewController, GADFullScreenContentDelegate, ObservableObject  {
    @Published var userViewModel = UserViewModel.shared
    @Published var adsWatched = 0
    
    var userVM = UserViewModel.shared
    var rewardedAd: GADRewardedAd?
    var onUserDidEarnReward: (() -> Void)?
    var onAdDidDismissFullScreenContent: (() -> Void)?
    
    func loadRewardedAd() {
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: Secrets.REWARD_AD_KEY, request: request) { [weak self] ad, error in
            if let error = error {
                print("Failed to load rewarded ad with error: \(error.localizedDescription)")
                // Optionally, handle the error by notifying the user or retrying
                return
            }
            self?.rewardedAd = ad
            print("Rewarded ad loaded.")
            self?.rewardedAd?.fullScreenContentDelegate = self
            
        }
    }
    
    
    func present(from viewController: UIViewController, rewardType: String) {
        if let ad = rewardedAd {
            ad.present(fromRootViewController: viewController, userDidEarnRewardHandler: { [weak self] in
                guard let self = self else { return }
                
                switch rewardType {
                case "credits":
                    userViewModel.addCredits(1)
                    
                case "favorites":
                    CoffeeShopData.shared.hadnleAdsWatchedCount()
                    
                default:
                    break
                }
                loadRewardedAd() // Load a new ad
            })
        } else {
            print("Rewarded ad not available, loading ad.")
            loadRewardedAd()
        }
    }
    
    func isAdAvailable() -> Bool {
        let adAvailable = rewardedAd != nil
        print("Checking if ad is available: \(adAvailable)")
        return adAvailable
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    /// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
    }
    
    /// Tells the delegate that the ad will present full screen content.
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad will present full screen content.")
    }
    
    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        loadRewardedAd()
    }
}
