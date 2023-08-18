//
//  CoffeeOrder.swift
//  Brewies
//
//  Created by Noah Boyers on 7/24/23.
//

import Foundation

struct CoffeeOrder {
    var item: CoffeeMenuItem
    var selectedModifiers: [String: String] = [:] // e.g. ["Size": "Medium", "Hot/Iced": "Hot"]
    var quantity: Int = 1
    var taxRate: Double = 0
}

struct CoffeeMenuItem: Identifiable {
    var id = UUID()
    var name: String
    var price: Double
    var category: String
    var modifiers: [ModifierType]
}

struct ModifierOption {
    var name: String
    var price: Double
}

struct ModifierType {
    var title: String
    var options: [ModifierOption]
    var singleSelection: Bool
}


extension ModifierOption: Equatable {
    static func == (lhs: ModifierOption, rhs: ModifierOption) -> Bool {
        return lhs.name == rhs.name && lhs.price == rhs.price
    }
}
