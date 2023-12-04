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
    @Environment(\.openURL) var openURL
    
    @State var isPurchased = false
    @State var purchasedProduct: Product?
    
    var body: some View {
        VStack(spacing: 15) { // Add spacing between VStack elements
            Spacer()
            Text("Brewies+")
                .bold()
                .font(.largeTitle)
            
            GeometryReader { geo in
                VStack(alignment: .leading) { // Add spacing between VStack elements
                    Text("Features")
                        .bold()
                    Divider()
                    
                    Group {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("No banner ads")
                        }
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("25/40/50 discover credits welcome bonus")
                        }
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("More Filtering Options")
                        }
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("20 Favorite's Slots")
                        }
                    }
                    .font(.system(size: geo.size.width * 0.05 - 5))
                    
                    
                    Section() {
                        ForEach(storeKitManager.storeStatus.storeProducts.sorted(by: { $0.displayName < $1.displayName }).filter({ product in
                            // Assuming 'adRemovalProductId', 'creditsProductId', and 'favoritesSlotId' are non-subscription products
                            [StoreKitManager.monthlyID, StoreKitManager.semiYearlyID, StoreKitManager.yearlyID].contains(product.id)
                        })) { product in
                            Button(action: {
                                Task {
                                    await buy(product: product)
                                }
                            }) {
                                HStack {
                                    Text(product.displayName)
                                    
                                    if UserDefaults.standard.string(forKey: "CurrentSubscriptionID") == product.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .lineLimit(nil)
                                .minimumScaleFactor(0.95)
                                .frame(width: geo.size.width - 50, height: geo.size.height/66) // Adjust height
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hex: "#f7b32b"))
                                .cornerRadius(15.0)
                                
                            }
                            Text(product.description)
                                .font(.caption)
                                .padding(.horizontal, 10) // Add some padding
                        }
                    }
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            openURL(URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        }) {
                            Text("terms of service")
                                .font(.footnote)
                        }
                        Spacer()
                        Button(action: {
                            openURL(URL(string: "https://nobosoftware.com/privacy")!)
                        }) {
                            Text("privacy policy")
                                .font(.footnote)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color.black : Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
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
//            print("Purchase failed")
        }
    }
}

