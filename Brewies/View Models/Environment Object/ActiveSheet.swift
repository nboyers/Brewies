//
//  ActiveSheet.swift
//  Brewies
//
//  Created by Noah Boyers on 9/19/23.
//

import Foundation

public enum ActiveSheet: Identifiable {
    case filter, userProfile, signUpWithApple, storefront, detailBrew,shareApp

    public var id: Int {
        switch self {
        case .filter:
            return 1
        case .userProfile:
            return 2
        case .signUpWithApple:
            return 3
        case .storefront:
            return 4
        case .detailBrew:
            return 5
        case .shareApp:
            return 6
        }
        
    }
}
