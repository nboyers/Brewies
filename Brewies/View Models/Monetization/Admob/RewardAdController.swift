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

class RewardAdController: UIViewController, FullScreenContentDelegate, ObservableObject  {
    @Published var userViewModel = UserViewModel.shared
    @Published var adsWatched = 0
    
    var userVM = UserViewModel.shared
    var rewardedAd: RewardedAd?
    var onUserDidEarnReward: (() -> Void)?
    var onAdDidDismissFullScreenContent: (() -> Void)?
    private var isLoading = false
    private let adUnitID: String
    
    init(adUnitID: String = "ca-app-pub-3940256099942544/1712485313") {
        self.adUnitID = adUnitID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.adUnitID = "ca-app-pub-3940256099942544/1712485313"
        super.init(coder: coder)
    }
    
    func loadRewardedAd() {
        guard !isLoading && rewardedAd == nil else { return }
        isLoading = true
        
        let request = Request()
        RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            self?.isLoading = false
            if let error = error {
                print("Failed to load rewarded ad with error: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
            print("Rewarded ad loaded.")
            self?.rewardedAd?.fullScreenContentDelegate = self
        }
    }
    
    
    func present(from viewController: UIViewController, rewardType: String) {
        if let ad = rewardedAd {
            rewardedAd = nil // Clear current ad
            ad.present(from: viewController, userDidEarnRewardHandler: { [weak self] in
                guard let self = self else { return }
                
                switch rewardType {
                case "credits":
                    userViewModel.addCredits(1)
                    
                case "favorites":
                    CoffeeShopData.shared.hadnleAdsWatchedCount()
                    
                default:
                    break
                }
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
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
    }
    
    /// Tells the delegate that the ad will present full screen content.
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad will present full screen content.")
    }
    
    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Don't automatically reload - only load when needed
    }
}

