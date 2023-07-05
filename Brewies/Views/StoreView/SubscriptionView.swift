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
    @State var isPurchased = false

    var body: some View {
        Group {
            Section("Upgrade to Premium") {
                ForEach(storeVM.subscriptions) { product in
                    Button(action: {
                        Task {
                            await buy(product: product)
                        }
                    })
                    {
                        VStack {
                            HStack {
                                Text(product.displayPrice)
                                Text(product.displayName)
                            }
                            Text(product.description)
                        }.padding()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(.blue)
                    .cornerRadius(15.0)
                }
            }
        }
    }
    
    func buy(product: Product) async {
        do {
            if try await storeVM.purchase(product) != nil {
                isPurchased = true
            }
        } catch {
            print("purchase failed")
        }
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
            .environmentObject(StoreKitManager())
    }
}
