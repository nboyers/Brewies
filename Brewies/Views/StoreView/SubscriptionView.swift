//
//  SubscriptionView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/5/23.
//
import SwiftUI
import StoreKit
struct SubscriptionView: View {
    @EnvironmentObject var storeVM: StoreKitManager
    @StateObject var userVM = UserViewModel.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    @State var isPurchased = false
    @State var purchasedProduct: Product?
    let signInCoordinator = SignInWithAppleCoordinator()
    
    var body: some View {
        if userVM.user.isLoggedIn {
            VStack(spacing: 20) { // Add spacing between VStack elements
                Spacer()
                Text("Brewies+")
                    .bold()
                    .font(.largeTitle)
                
                GeometryReader { geo in
                    VStack(alignment: .leading, spacing: 5) { // Add spacing between VStack elements
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
                        .font(.system(size: geo.size.width <= 350 ? 11 : 17))
                        
                        
                        Section() {
                            ForEach(storeVM.subscriptions.sorted(by: { $0.displayName < $1.displayName })) { product in
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
                                    .frame(width: geo.size.width - 40, height: geo.size.height/66) // Adjust height
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(.brown)
                                    .cornerRadius(15.0)
                                    
                                }
                                
                                
                                Text(product.description)
                                    .font(.caption)
                                    .padding(.horizontal, 10) // Add some padding
                                
                            }
                        }
                        Spacer()
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
//            .onAppear(perform: setup)
        } else {
            VStack {
                Text("Sign in to Subscribe")
                    .font(.largeTitle)  // Using a larger font size for emphasis
                    .fontWeight(.semibold)  // Adding some weight to the font for better readability
                    .foregroundColor(Color.primary)  // Using the primary color which adapts to light/dark mode
                    .padding()  // Adding some padding around the text for better spacing
                    .multilineTextAlignment(.center)  // Center-aligning the text
                Text("Enchance your Brewies Experience")
                    .font(.footnote)
                    .fontWeight(.semibold)  // Adding some weight to the font for better readability
                    .foregroundColor(Color.primary)  // Using the primary color which adapts to light/dark mode
                    .padding()  // Adding some padding around the text for better spacing
                    .multilineTextAlignment(.center)  // Ce
                
                SignInWithAppleButton(action: {
                    signInCoordinator.startSignInWithAppleFlow()
                }, label: "Sign in with Apple")
                .frame(width: 280, height: 45)
                .padding(.top, 50)
            }
        }
    }
    

    func buy(product: Product) async {
        do {
            if try await storeVM.purchase(product) != nil {
                // Purchase successful
                userVM.user.isSubscribed = true
                purchasedProduct = product
            }
        } catch {
            // print("Purchase failed")
        }
    }
}

