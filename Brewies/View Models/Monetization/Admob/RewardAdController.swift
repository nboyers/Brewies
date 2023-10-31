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
        GADRewardedAd.load(withAdUnitID: Secrets.REWARD_AD_KEY,
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
            })
        } else {
            loadRewardedAd()
        }
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        loadRewardedAd()  // Reload a new ad
    }
    
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        onAdDidDismissFullScreenContent?()
    }
}
