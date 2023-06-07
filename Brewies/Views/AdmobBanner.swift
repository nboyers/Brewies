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
        banner.adUnitID = Secrets.TEST_BANNER
        banner.rootViewController = UIApplication.shared.windows.first?.rootViewController
        banner.load(GADRequest())
        return banner
    }

    
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
