//
//  AdmobBanner.swift
//  Brewies
//
//  Created by Noah Boyers on 5/30/23.
//

import Foundation
import SwiftUI
import GoogleMobileAds
import UIKit

struct AdBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = Secrets.TEST_BANNER //FIXME: Change this to the live version once ready to ship
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            banner.rootViewController = rootViewController
        }
        
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
