//
//  SharedViewModel.swift
//  Brewies
//
//  Created by Noah Boyers on 9/8/23.
//

import Foundation
import BottomSheet

class SharedViewModel: ObservableObject {
    @Published var bottomSheetPosition: BottomSheetPosition = .relativeBottom(0.35)
    @Published var selectedBrew: BrewLocation?
}

