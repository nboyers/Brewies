//
//  ATTManager.swift
//  Brewies
//
//  Created by Noah Boyers on 12/19/24.
//

import Foundation
import AppTrackingTransparency
import AdSupport

class ATTManager: ObservableObject {
    @Published var trackingStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    
    init() {
        trackingStatus = ATTrackingManager.trackingAuthorizationStatus
    }
    
    func requestPermission() {
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.trackingStatus = status
            }
        }
    }
    
    var shouldRequestPermission: Bool {
        return trackingStatus == .notDetermined
    }
}