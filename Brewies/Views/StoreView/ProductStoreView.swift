//
//  ProductStoreView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/5/23.
//

import SwiftUI
import StoreKit

struct ProductStoreView: View {
    @EnvironmentObject var storeKitManager: StoreKitManager // Use the shared instance provided by the environment.
    @Environment(\.colorScheme) var colorScheme
    
    private var filteredProducts: [Product] {
        storeKitManager.storeStatus.storeProducts
            .sorted(by: { $0.displayName < $1.displayName })
            .filter { product in
                [StoreKitManager.adRemovalProductId, StoreKitManager.creditsProductId, StoreKitManager.favoritesSlotId].contains(product.id)
            }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
              headerView
                  .padding(.bottom, 10) // Adds some space below the header
              
              productsListView
                  .cardStyle() // Custom modifier for card styling
              
              restorePurchasesButton
                  .padding(.top, 20) // Adds space between the list and the button
          }
        
          .padding()
          .cornerRadius(10) // Rounded corners for the whole container
          .shadow(radius: 5) // Subtle shadow for depth
          .onReceive(storeKitManager.$storeStatus) { _ in
              // Action to be taken when store status changes.
          }
      }
    
    private var headerView: some View {
        Text("In-App Purchases")
            .bold()
    }
    
    private var productsListView: some View {
        ForEach(filteredProducts) { product in
            ProductItem(storeKit: storeKitManager, product: product)
            
            
        }
    }
    
    private var restorePurchasesButton: some View {
           return HStack {
               Spacer()
               Button("Restore Purchases") {
                   Task {
                       try? await AppStore.sync()
                       await storeKitManager.checkIfAdsRemoved()
                   }
               }
               .buttonStyle(ProfessionalButtonStyle()) // Custom button style
               Spacer()
           }
       }
   }

struct ProductItem: View {
    @ObservedObject var storeKit: StoreKitManager
    var product: Product
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            productTitle
            Spacer()
            purchaseOrBoughtView
        }
       
    }
    
    private var productTitle: some View {
        Text(product.displayName)
            .foregroundColor(Color.init(hex: "#ffffff"))
    }
    
    private var purchaseOrBoughtView: some View {
        Group {
            if storeKit.storeStatus.isAdRemovalPurchased && product.id == StoreKitManager.adRemovalProductId {
                purchasedLabel
            } else {
                purchaseButton
            }
        }
        
    }
    
    private var purchasedLabel: some View {
        Text("BOUGHT")
            .foregroundColor(.gray)
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.init(hex: "#d94a24"), lineWidth: 2)
            )
    }
    
    private var purchaseButton: some View {
        Button(action: purchaseAction) {
            Text(product.displayPrice)
                .padding(5)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.init(hex: "#a2a49f"))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func purchaseAction() {
        Task {
            do {
                _ = try await storeKit.purchase(product)
            } catch {
                // Handle errors if needed
            }
        }
    }
}

// MARK: - Custom Button Style
struct ProfessionalButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.black) // Custom color
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.95 : 1) // Slight shrink effect when pressed
    }
}

// MARK: - Entire Card Style Modifier
struct CardStyle: ViewModifier {
    let BUTTON_COLOR = Color.init(hex:"#947329")
    func body(content: Content) -> some View {
        content
            .padding()
            .background(BUTTON_COLOR)
            .cornerRadius(8)
            .shadow(radius: 3)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

#Preview {
        ProductStoreView()
            .environmentObject(StoreKitManager())
    }
