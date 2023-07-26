//
//  CoffeeOrder.swift
//  Brewies
//
//  Created by Noah Boyers on 7/24/23.
//

import Foundation

struct CoffeeOrder: Identifiable {
    var id = UUID()
    var item: CoffeeMenuItem
    var quantity: Int = 1
    var size: String = "Regular"
    var additives: [String] = []
}
