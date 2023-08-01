//
//  CoffeeModiferView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/31/23.
//
import SwiftUI

struct CoffeeModiferView: View {
    var coffeeMenuItem: CoffeeMenuItem
    @Binding var order: CoffeeOrder
    let BUTTON_WIDTH = 300.0
    
    @State private var quantity: Int = 1
    @State private var selectedModifiers: [String: [String]] = [:]
    
    var selectedAdditivesPrice: Double {
        var price: Double = 0.0
        for modifier in coffeeMenuItem.modifiers {
            for option in modifier.options {
                if selectedModifiers[modifier.title]?.contains(option.name) == true {
                    price += option.price
                }
            }
        }
        return price
    }
    
    var totalPrice: Double {
        (coffeeMenuItem.price + selectedAdditivesPrice) * Double(quantity)
    }
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(coffeeMenuItem.name)
                    .font(.title)
                    .bold()
                Spacer()
                Text("$\(coffeeMenuItem.price, specifier: "%.2f")")
                    .font(.title2)
                    .bold()
            }
            
            Form {
                ForEach(coffeeMenuItem.modifiers, id: \.title) { modifier in
                    VStack {
                        Text(modifier.title)
                            .font(.headline)
                        
                        //FIXME: The Buttons click as a single unit rather than each button on their own
                        ForEach(modifier.options, id: \.name) { option in
                            Button(action: {
                                if modifier.singleSelection {
                                    // For single selection modifiers, toggle selection
                                    if selectedModifiers[modifier.title]?.contains(option.name) == true {
                                        selectedModifiers[modifier.title] = []
                                    } else {
                                        selectedModifiers[modifier.title] = [option.name]
                                    }
                                } else {
                                    // For multi-selection modifiers
                                    if selectedModifiers[modifier.title]?.contains(option.name) == true {
                                        selectedModifiers[modifier.title]?.removeAll { $0 == option.name }
                                    } else {
                                        selectedModifiers[modifier.title, default: []].append(option.name)
                                    }
                                }
                            })
                            {
                                HStack {
                                    Text(option.name)
                                    Spacer()
                                    if option.price > 0 {
                                        Text("+ $\(String(format: "%.2f", option.price))")
                                            .font(.subheadline)
                                    }
                                }
                                .padding()
                                .background(selectedModifiers[modifier.title]?.contains(option.name) == true ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .padding(.bottom, 5)
                            .id(option.name + modifier.title) // Unique ID for each button
                        }
                    }
                }
                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
            }
            Spacer()
            Button(action: {
                //TODO: Update button and dismiss back to MenuView
            }) {
                HStack {
                    Text("Add \(quantity) to cart")
                    Text("$\(totalPrice, specifier: "%.2f")")
                }
                .frame(width: BUTTON_WIDTH)
                .padding()
                .background(Color.red)
                .cornerRadius(8)
                .foregroundColor(.white)
                .padding([.leading, .trailing])
            }
        }
        .padding([.leading, .trailing])
    }
}

struct CoffeeModiferView_Previews: PreviewProvider {
    @State static var orderPreview = CoffeeOrder(
        item: CoffeeMenuItem(
            name: "Espresso",
            price: 2.50,
            category: "Espresso",
            modifiers: [
                ModifierType(title: "Size", options: [
                    ModifierOption(name: "Regular", price: 0.0),
                    ModifierOption(name: "Long Shot", price: 0.5),
                    ModifierOption(name: "Ristretto", price: 0.75)
                ], singleSelection: true),
                ModifierType(title: "Additives", options: [
                    ModifierOption(name: "Extra Shot", price: 1.0),
                    ModifierOption(name: "2 Shots", price: 2.0)
                ], singleSelection: true)
            ]
        )
    )
    
    static var previews: some View {
        CoffeeModiferView(coffeeMenuItem: orderPreview.item, order: $orderPreview)
    }
}
