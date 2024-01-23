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
    @State private var isPurchasing: Bool = false // Add a loading state

    var product: Product
    let BUTTON_COLOR = Color.init(hex:"#947329")
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: purchaseAction) {
            HStack {
                productTitle
                Spacer()
                purchaseOrBoughtView
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Ensure the button fills the entire width
            .padding() // Add padding inside the button for better touch area
        }
        .buttonStyle(PlainButtonStyle())
        .background(BUTTON_COLOR) // Background color for the button
        .cornerRadius(10) // Rounded corners for the button
        .shadow(radius: 5) // Shadow for the button
    }
    
    
    private var productTitle: some View {
        Text(product.displayName)
            .foregroundColor(Color.init(hex: "#ffffff"))
    }
    
    private var purchaseOrBoughtView: some View {
        Group {
            if storeKit.storeStatus.isAdRemovalPurchased && product.id == StoreKitManager.adRemovalProductId {
                purchasedLabel
            } else if isPurchasing {
                ProgressView() // Show loading indicator while purchasing
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text(product.displayPrice)
                    .padding(5)
                    .foregroundColor(.white)
            }
        }
    }
    
    private var purchasedLabel: some View {
        Text("BOUGHT")
            .foregroundColor(.white)
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.red, lineWidth: 2)
            )
    }
    
    private func purchaseAction() {
           guard !isPurchasing else { return } // Prevent multiple taps
           isPurchasing = true
           Task {
               do {
                   _ = try await storeKit.purchase(product)
               } catch {
                   // Handle errors if needed
               }
               isPurchasing = false
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

    func body(content: Content) -> some View {
        content
            .padding()
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
