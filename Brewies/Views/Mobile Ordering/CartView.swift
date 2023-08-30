////
////  CartView.swift
////  Brewies
////
////  Created by Noah Boyers on 7/24/23.
////
//
//import SwiftUI
//
//struct CartView: View {
//    var orders: [CoffeeOrder]
//    
//    let processingFee: Double = 0.30
//    let taxRate: Double = 0.075
//    
//    var subtotal: Double {
//        orders.map { $0.item.price }.reduce(0, +)
//    }
//    
//    var tax: Double {
//        subtotal * taxRate
//    }
//    
//    var total: Double {
//        subtotal + tax + processingFee
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading) {
//            List {
//                ForEach(orders, id: \.item.name) { order in
//                    HStack {
//                        Text(order.item.name)
//                        Spacer()
//                        Text("$\(order.item.price, specifier: "%.2f")")
//                    }
//                }
//                
//                Spacer()
//                VStack {
//                    HStack {
//                        Text("Subtotal")
//                        Spacer()
//                        Text("$\(subtotal, specifier: "%.2f")")
//                    }
//                    
//                    HStack {
//                        Text("Processing Fee")
//                        Spacer()
//                        Text("$\(processingFee, specifier: "%.2f")")
//                    }
//                    
//                    HStack {
//                        Text("Tax")
//                        Spacer()
//                        Text("$\(tax, specifier: "%.2f")")
//                    }
//                    
//                    HStack {
//                        Text("Total")
//                            .bold()
//                        Spacer()
//                        Text("$\(total, specifier: "%.2f")")
//                            .bold()
//                    }
//                }
//            }
//            
//            Button(action: {
//                // Action to pay with Apple
//            }) {
//                HStack {
//                    Spacer()
//                    Text("Buy with")
//                        .font(.title)
//                    Image(systemName: "apple.logo")
//                        .font(.title)
//                    Text("Pay")
//                        .font(.title)
//                    Spacer()
//                }
//                .padding()
//                .background(Color.black)
//                .foregroundColor(.white)
//                .cornerRadius(100)
//            }
//            .padding([.top, .bottom, .leading, .trailing])
//        }
//        .navigationBarTitle("Cart", displayMode: .inline)
//    }
//}
//
//
//struct CartView_Previews: PreviewProvider {
//    static var sampleOrders: [CoffeeOrder] = [
//        CoffeeOrder(item: CoffeeMenuItem(
//            name: "Espresso",
//            price: 2.50,
//            category: "Espresso",
//            modifiers: [
//                ModifierType(title: "Size", options: [
//                    ModifierOption(name: "Regular", price: 0.0),
//                    ModifierOption(name: "Long Shot", price: 0.5),
//                    ModifierOption(name: "Ristretto", price: 0.75)
//                ], singleSelection: true),
//                ModifierType(title: "Additives", options: [
//                    ModifierOption(name: "Extra Shot", price: 1.0),
//                    ModifierOption(name: "2 Shots", price: 2.0)
//                ], singleSelection: true)
//            ]
//        )),
//        CoffeeOrder(item: CoffeeMenuItem(
//            name: "Latte",
//            price: 3.50,
//            category: "Espresso",
//            modifiers: [
//                ModifierType(title: "Size", options: [
//                    ModifierOption(name: "Small", price: 0.0),
//                    ModifierOption(name: "Medium", price: 0.5),
//                    ModifierOption(name: "Large", price: 1.0)
//                ], singleSelection: true),
//                ModifierType(title: "Additives", options: [
//                    ModifierOption(name: "Vanilla", price: 0.0),
//                    ModifierOption(name: "Chocolate", price: 0.0),
//                    ModifierOption(name: "Caramel", price: 0.5)
//                ], singleSelection: false)
//            ]
//        ))]
//    
//    static var previews: some View {
//        NavigationView {
//            CartView(orders: sampleOrders)
//        }
//    }
//}
