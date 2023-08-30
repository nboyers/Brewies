////
////  FoodDetailView.swift
////  Brewies
////
////  Created by Noah Boyers on 7/31/23.
////
//
//import SwiftUI
//
//struct FoodDetailView: View {
//    @State private var quantity = 1
//    @State private var specialInstructions = ""
//    var coffeeItem: CoffeeMenuItem
//    let BUTTON_WIDTH = 300.0
//    
//    var totalPrice: Double {
//        Double(quantity) * coffeeItem.price
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading) {
//            HStack {
//                Text(coffeeItem.name)
//                    .font(.title)
//                    .bold()
//                Spacer()
//                Text("$\(coffeeItem.price, specifier: "%.2f")")
//                    .font(.title2)
//                    .bold()
//            }
//            
//            Stepper(value: $quantity, in: 1...100) {
//                Text("Quantity: \(quantity)")
//                    .font(.title3)
//                    .bold()
//            }
//            
//            Spacer()
//                .frame(height: 30)
//            Text("Special Instructions")
//                .font(.title3)
//                .bold()
//            TextField("Examples: utensils, extra condiments, etc", text: $specialInstructions)
//                .padding()
//                .overlay(
//                    RoundedRectangle(cornerRadius: 8)
//                        .stroke(Color.gray, lineWidth: 1)
//                )
//            Spacer()
//            Button(action: {
//                //TODO: Update button and dismiss back to MenuView
//            }) {
//                HStack {
//                    Text("Add \(quantity) to cart")
//                    Text("$\(totalPrice, specifier: "%.2f")")
//                }
//                .frame(width: BUTTON_WIDTH)
//                .padding()
//                .background(Color.red)
//                .cornerRadius(8)
//                .foregroundColor(.white)
//                .padding([.leading, .trailing])
//            }
//        }
//        .padding([.leading, .trailing])
//    }
//}
//
//struct FoodDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        FoodDetailView(coffeeItem:
//                        CoffeeMenuItem(name: "Blueberry Muffin",
//                                       price: 2.50,
//                                       category: "Pasteries",
//                                       
//                                       modifiers: [
//                                        
//                                        ModifierType(title: "", options: [], singleSelection: true)
//                                       ]))
//    }
//}
