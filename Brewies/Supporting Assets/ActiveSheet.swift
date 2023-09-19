//
//  ActiveSheet.swift
//  Brewies
//
//  Created by Noah Boyers on 9/19/23.
//

import Foundation

public enum ActiveSheet: Identifiable {
    case settings, filter, userProfile, signUpWithApple, storefront, detailBrew

    public var id: Int {
        switch self {
        case .settings:
            return 1
        case .filter:
            return 2
        case .userProfile:
            return 3
        case .signUpWithApple:
            return 4
        case .storefront:
            return 5
        case .detailBrew:
            return 6
        }
    }
}
