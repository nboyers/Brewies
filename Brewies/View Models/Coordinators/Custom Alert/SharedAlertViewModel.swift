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
    
    @Published var showAdAlert: Bool = false
    @Published var showLoginAlert: Bool = false
    @Published var showTimeLeftAlert: Bool = false
    @Published var showInstructions: Bool = false
}

enum CustomAlertType {
    case insufficientCredits
    case maxFavoritesReached
    case notSubscribed
}
