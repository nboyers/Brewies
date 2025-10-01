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
    
    private func topMostViewController(from root: UIViewController?) -> UIViewController? {
        guard let root = root else { return nil }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        if let nav = top as? UINavigationController {
            return nav.visibleViewController ?? nav
        }
        if let tab = top as? UITabBarController {
            return tab.selectedViewController ?? tab
        }
        return top
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Start loading ads immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadRewardedAd()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadRewardedAd()
        }
    }
    
    func loadRewardedAd() {
        // Prevent loading if ad is already available
        if let existing = rewardedAd {
            existing.fullScreenContentDelegate = self
            print("Rewarded ad already loaded, skipping.")
            return
        }
        
        let request = Request()

        let adUnitID = Bundle.main.infoDictionary?["REWARD_AD_KEY"] as? String ?? "ca-app-pub-3940256099942544/1712485313"
        print("Loading rewarded ad with ID: \(adUnitID)")
        RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to load rewarded ad with error: \(error.localizedDescription)")
                    // Retry after 60 seconds to avoid throttling
                    DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                        self?.loadRewardedAd()
                    }
                    return
                }
                self?.rewardedAd = ad
                print("Rewarded ad loaded successfully.")
                self?.rewardedAd?.fullScreenContentDelegate = self
            }
        }
    }
    
    
    func present(from viewController: UIViewController, rewardType: String) {
        let presenter = topMostViewController(from: viewController) ?? viewController

        if let ad = rewardedAd {
            ad.present(from: presenter, userDidEarnRewardHandler: { [weak self] in
                guard let self = self else { return }
                
                switch rewardType {
                case "credits":
                    userViewModel.addCredits(1)
                    
                case "favorites":
                    CoffeeShopData.shared.hadnleAdsWatchedCount()
                    
                default:
                    break
                }
                self.loadRewardedAd() // Load a new ad
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
        print("[RewardAdController] Ad failed to present full screen content: \(error.localizedDescription)")
        self.rewardedAd = nil
        self.loadRewardedAd()
    }
    
    /// Tells the delegate that the ad will present full screen content.
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad will present full screen content.")
    }
    
    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        loadRewardedAd()
    }
}

