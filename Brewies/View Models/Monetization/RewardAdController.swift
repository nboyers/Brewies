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
    
    private var rewardedAd: GADRewardedAd?
    
    func requestIDFA() {
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            switch status {
            case .authorized:
                // Tracking authorization dialog was shown
                // and permission was granted
                print(ASIdentifierManager.shared().advertisingIdentifier)
            case .denied:
                // Tracking authorization dialog was
                // shown and permission was denied
                break
            case .notDetermined:
                // Tracking authorization dialog has not yet been presented
                break
            case .restricted:
                // The device is not eligible for tracking
                break
            @unknown default:
                // A new case was added that we need to handle
                break
            }
            // Call `loadRewardedAd()` after getting IDFA status
            self?.loadRewardedAd()
        }
    }
    
    func loadRewardedAd() {
        let request = GADRequest()
        
        GADRewardedAd.load(withAdUnitID: Secrets.TEST_REWARD, //FIXME: Change this to the live version once ready to ship
                           request: request,
                           completionHandler: { [self] ad, error in
            if let error = error {
                print("Failed to load rewarded ad with error: \(error.localizedDescription)")
                return
            }
            rewardedAd = ad
            rewardedAd?.fullScreenContentDelegate = self
            print("Rewarded ad loaded.")
        }
        )
    }
    
    func present(from viewController: UIViewController) {
        if let ad = rewardedAd {
            ad.present(fromRootViewController: viewController, userDidEarnRewardHandler: { })
        } else {
            print("Tried to show rewarded ad before it was loaded.")
        }
    }
    
    func show() -> Bool {
        if let ad = rewardedAd {
            ad.present(fromRootViewController: self) {}
        } else {
            return false
        }
        return true
    }
    
    //// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
    }
    
    /// Tells the delegate that the ad will present full screen content.
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad will present full screen content.")
    }
    
    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
    }
}
