//
//  SharedAlertViewModel.swift
//  Brewies
//
//  Created by Noah Boyers on 9/4/23.
//

import Foundation

class SharedAlertViewModel: ObservableObject {
    @Published var showCustomAlert: Bool = false
    @Published var currentAlertType: CustomAlertType?
}

enum CustomAlertType {
    case insufficientCredits
    case maxFavoritesReached
}
