//
//  CoffeeMenuItem.swift
//  Brewies
//
//  Created by Noah Boyers on 7/24/23.
//

import Foundation

struct CoffeeMenuItem: Identifiable {
    var id = UUID()
    var name: String
    var price: Double
    var category: String
}

