//
//  ActiveSheet.swift
//  Brewies
//
//  Created by Noah Boyers on 9/19/23.
//

import Foundation

public enum ActiveSheet: Identifiable {
    case filter, storefront, detailBrew, shareApp, searchResults

    public var id: Int {
        switch self {
        case .filter:
            return 1
        case .storefront:
            return 2
        case .detailBrew:
            return 3
        case .shareApp:
            return 4
        case .searchResults:
            return 5
        }
    }
}
