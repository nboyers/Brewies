//
//  SubscriptionView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/5/23.
//
import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var storeKitManager: StoreKitManager
    
    @StateObject var userVM = UserViewModel.shared
    @Environment(\.colorScheme) var colorScheme
    
    let BUTTON_COLOR = Color.init(hex:"#826c3b")
    let SUB_BACKGROUND = Color.init(hex: "#303c38")
    @State var isPurchased = false
    @State var purchasedProduct: Product?
    
    var body: some View {
        VStack(spacing: 15) {
            GeometryReader { geo in
                VStack(alignment: .leading) {
                    Spacer()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .center, spacing: 20) {
                            Section {
                                ForEach(storeKitManager.storeStatus.storeProducts.sorted(by: { $0.displayName < $1.displayName }).filter({ product in
                                    [StoreKitManager.monthlyID, StoreKitManager.yearlyID].contains(product.id)
                                })) { product in
                                    VStack(alignment: .leading) {
                                        SubscriptionOptionView(product: product, geo: geo)
                                        
                                        // Feature list for each subscription option
                                        VStack(alignment: .leading, spacing: 8) {  // Adjusted spacing
                                            Text("Features:")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding([.horizontal, .vertical], 10)
                                            
                                            FeatureView(iconName: "checkmark.circle.fill", featureText: "No banner ads")
                                            FeatureView(iconName: "checkmark.circle.fill", featureText: "More Filtering Options")
                                            FeatureView(iconName: "checkmark.circle.fill", featureText: "20 Favorite's Slots")
                                            
                                            Text(welcomeCreditsText(for: product))
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .foregroundColor(.white)
                                                .padding(.leading, 22)
                                        }
                                        .padding(.bottom, 10) // Extra padding at the bottom
                                        
                                        Divider()
                                            .padding(.vertical, 5)
                                        
                                        Text(product.description)
                                            .lineLimit(1) // Ensure the text stays within one line
                                            .truncationMode(.tail) // If the text doesn't fit, it will truncate at the end
                                            .foregroundColor(.white)
                                            .padding(.leading, 22)
                                            .minimumScaleFactor(0.5) // Allow the font to scale down to 50% if necessary
                                    }
                                    .padding()
                                    .frame(width: geo.size.width * 0.85)
                                    .background(SUB_BACKGROUND)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                }
                            }
                        }
                    }
                    .frame(minHeight: 0, maxHeight: .infinity) // Allow the ScrollView to take as much height as needed
                    .padding(.horizontal, 10)
                    Spacer()
                }
            }
            .padding()
        }
    }
    
    private func buy(product: Product) async {
        do {
            if try await storeKitManager.purchase(product) != nil {
                // Purchase successful
                userVM.user.isSubscribed = true
                purchasedProduct = product
            }
        } catch {
            // Handle the purchase failure
            // For instance, you can log the error or present an alert to the user
        }
    }
    
    // Function to determine the welcome credits text based on product id
    private func welcomeCreditsText(for product: Product) -> String {
        switch product.id {
        case StoreKitManager.monthlyID:
            return "100 discover credits welcome bonus"
        case StoreKitManager.yearlyID:
            return "250 discover credits welcome bonus"
        default:
            return ""
        }
    }
    
    
    @ViewBuilder
    private func SubscriptionOptionView(product: Product, geo: GeometryProxy) -> some View {
        Button(action: {
            Task {
                await buy(product: product)
            }
        }) {
            HStack {
                Text(product.displayName)
                    .foregroundColor(Color.white)
                
                if UserDefaults.standard.string(forKey: "CurrentSubscriptionID") == product.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.green)
                }
            }
            .lineLimit(nil)
            .minimumScaleFactor(0.95)
            .frame(width: geo.size.width * 0.75, height: geo.size.height / 30)
            .foregroundColor(.white)
            .padding()
            .background(BUTTON_COLOR)
            .cornerRadius(15.0)
        }
    }
}


struct FeatureView: View {
    var iconName: String
    var featureText: String
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: iconName)
                .foregroundColor(Color.green)
                .padding(.horizontal)
            Text(featureText)
                .foregroundColor(.white)
        }
        
    }
}


#Preview {
    SubscriptionView()
        .environmentObject(StoreKitManager())
}

