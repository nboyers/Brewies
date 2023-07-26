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

class RewardAdController: UIViewController, GADFullScreenContentDelegate {
    
    var userVM = UserViewModel.shared
    var rewardedAd: GADRewardedAd?
    var onUserDidEarnReward: (() -> Void)?
    var onAdDidDismissFullScreenContent: (() -> Void)?
    
    func requestIDFA() {
        ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
            self?.loadRewardedAd()
        }
    }
    
    func loadRewardedAd() {
        let request = GADRequest()
        
        GADRewardedAd.load(withAdUnitID: Secrets.TEST_REWARD, //FIXME: Change this to the live version once ready to ship
                           request: request,
                           completionHandler: { [self] ad, error in
            if error != nil {
                return
            }
            rewardedAd = ad
            rewardedAd?.fullScreenContentDelegate = self
        })
    }
    
    func present(from viewController: UIViewController)  {
        if let ad = rewardedAd {
            ad.present(fromRootViewController: viewController, userDidEarnRewardHandler: { [weak self] in
                // When the ad completes, call the callback function
                self?.onUserDidEarnReward?()
                
                // Increment the user's credits by one
                self?.userVM.addCredits(1)
            })
        } else {
            loadRewardedAd()
        }
    }
    
    
    //// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        loadRewardedAd()  // Reload a new ad
    }
    
    
    /// Tells the delegate that the ad will present full screen content.
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    }
    
    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        onAdDidDismissFullScreenContent?()
    }
}
