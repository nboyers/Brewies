//
//  User.swift
//  Brewies
//
//  Created by Noah Boyers on 6/9/23.
//

import Foundation


import SwiftUI

class User: ObservableObject {
    @Published var isLoggedIn: Bool
    @Published var firstName: String
    @Published var profileImage: Image?

    init(isLoggedIn: Bool = false, firstName: String = "", profileImage: Image? = nil) {
        self.isLoggedIn = isLoggedIn
        self.firstName = firstName
        self.profileImage = profileImage
    }
}
