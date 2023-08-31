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
    
    @State var isPurchased = false
    @State var purchasedProduct: Product?
    let signInCoordinator = SignInWithAppleCoordinator()
    
    var body: some View {
        if userVM.user.isLoggedIn {
            VStack {
                Text("Brewies+")
                    .bold()
                    .font(.largeTitle)
                
                VStack(alignment: .leading){
                    Text("Features")
                        .bold()
                    Divider()
                    
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
                .padding()
                .background(colorScheme == .dark ? Color.black : Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                
                Section() {
                    ForEach(storeVM.subscriptions) { product in
                        Button(action: {
                            Task {
                                await buy(product: product)
                            }
                        }) {
                            HStack {
                                Text(product.displayName)
                                    .padding()
                                
                                // Checkmark if this product has been purchased
                                if product == purchasedProduct {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .frame(width: 300, height: 20)
                        .foregroundColor(.white)
                        .padding()
                        .background(.brown)
                        .cornerRadius(15.0)
                        Text(product.description)
                            .font(.caption)
                    }
                }
            }  .onAppear(perform: setup)
        } else {
            VStack {
                Text("Please sign in to view.")
                SignInWithAppleButton(action: {
                    signInCoordinator.startSignInWithAppleFlow()
                }, label: "Sign in with Apple")
                .frame(width: 280, height: 45)
                .padding(.top, 50)
            }
        }
    }

    func setup() {
          Task {
              await storeVM.updateCustomerProductStatus()
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
            print("Purchase failed")
        }
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
            .environmentObject(StoreKitManager())
    }
}
