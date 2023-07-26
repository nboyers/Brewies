//
//  ModifierView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/24/23.
//

import SwiftUI

struct ModifierView: View {
    @Binding var order: CoffeeOrder
    var dismissAction: () -> Void
    
    @State private var quantity: Int = 1
    @State private var size: String = "Regular"
    @State private var additives: [String] = []
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...10)
                    Picker("Size", selection: $size) {
                        Text("Small").tag("Small")
                        Text("Regular").tag("Regular")
                        Text("Large").tag("Large")
                    }
                    MultipleSelectionList(title: "Additives", items: ["Milk", "Sugar", "Caramel"], selection: $additives)
                }
            }
            Button("Add \(additives.count) to Order") {
                order.quantity = quantity
                order.size = size
                order.additives = additives
                dismissAction()
            }

        }
    }
}
