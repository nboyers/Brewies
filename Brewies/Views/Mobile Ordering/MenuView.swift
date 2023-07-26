//
//  MenuView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/24/23.
//

import SwiftUI

struct MenuView: View {
    @State private var selectedOrder: CoffeeOrder?
    @State private var isSheetPresented: Bool = false
    @State private var cartItems: [CoffeeMenuItem] = []
    @State private var totalPrice: Double = 0.00
    @State private var totalQuantity: Int = 0
    let BUTTON_WIDTH = 300.0
    let menuItems: [CoffeeMenuItem] = [
        CoffeeMenuItem(name: "Espresso", price: 2.50, category: "Espresso"),
        CoffeeMenuItem(name: "Latte", price: 3.50, category: "Espresso"),
        CoffeeMenuItem(name: "Cappuccino", price: 3.00, category: "Espresso"),
        CoffeeMenuItem(name: "Blueberry Muffin", price: 2.50, category: "Pastries"),
        CoffeeMenuItem(name: "Croissant", price: 2.75, category: "Pastries"),
        CoffeeMenuItem(name: "Drip Coffee", price: 2.75, category: "Coffee & Tea"),
        CoffeeMenuItem(name: "Green Tea", price: 2.75, category: "Coffee & Tea"),
        CoffeeMenuItem(name: "Cold Brew", price: 2.75, category: "Coffee & Tea"),
        CoffeeMenuItem(name: "Black Tea", price: 2.75, category: "Coffee & Tea")
    ]
    init(cartItems: [CoffeeMenuItem] = [], totalPrice: Double = 0.00, totalQuantity: Int = 0) {
        _cartItems = State(initialValue: cartItems)
        _totalPrice = State(initialValue: totalPrice)
        _totalQuantity = State(initialValue: totalQuantity)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { proxy in
                    List {
                        ForEach(groupedMenuItems().sorted(by: { $0.key < $1.key }), id: \.key) { key, items in
                            Section(header:
                                        HStack {
                                Text(key)
                                    .foregroundColor(.black)
                                    .font(.headline)
                                    .bold()
                                Spacer()
                                Button(action: {}, label: {
                                    Image(systemName: "ellipsis.circle")
                                        .contextMenu {
                                            ForEach(groupedMenuItems().keys.sorted(), id: \.self) { category in
                                                Button(action: {
                                                    withAnimation {
                                                        proxy.scrollTo(category, anchor: .top)
                                                    }
                                                }, label: {
                                                    Text(category)
                                                })
                                            }
                                        }
                                })
                            }
                                .id(key)
                            ) {
                                ForEach(items) { item in
                                    Button(action: {
                                        
                                    }, label: {
                                        HStack {
                                            Text(item.name)
                                                .foregroundColor(.black)
                                            Spacer()
                                            Text("$\(String(format: "%.2f", item.price))")
                                                .foregroundColor(.black)
                                        }
                                    })
                                }
                            }
                        }
                    }
                    .listStyle(GroupedListStyle())
                    .navigationTitle("Company X Coffee")
                }
                if cartItems.isEmpty {
                    Button("Your cart is empty") {}
                        .disabled(true)
                        .frame(width: BUTTON_WIDTH)
                        .padding()
                        .foregroundColor(.gray)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .padding([.leading, .trailing, .bottom])
                } else {
                    Button(action: {
                        //TODO: Action to view the cart
                    }) {
                        HStack {
                            Text("\(totalQuantity)")
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5.0)
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 25, height: 25)
                                )
                                .padding(.leading)
                            Spacer()
                            Text("View Cart")
                                .padding(.leading)
                            Spacer()
                            Text("$\(String(format: "%.2f", totalPrice))")
                                .padding(.leading)
                        }
                    }
                    
                    .frame(width: BUTTON_WIDTH)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .padding([.leading, .trailing])
                }
                
            }
            
        }
    }
    func groupedMenuItems() -> [String: [CoffeeMenuItem]] {
        return Dictionary(grouping: menuItems, by: { $0.category })
    }
    
    // Add item to cart function (you can modify this to fit your needs)
    func addToCart(item: CoffeeMenuItem) {
        cartItems.append(item)
        totalPrice += item.price
        totalQuantity += 1
    }
    
}

//struct MenuView_Previews: PreviewProvider {
//    static var previews: some View {
//        MenuView(cartItems: [CoffeeMenuItem(name: "Latte", price: 3.50, category: "Espresso")], totalPrice: 3.50, totalQuantity: 1)
//    }
//}
//
struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
