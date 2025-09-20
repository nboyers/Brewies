//
//  StorefrontView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/6/23.
//

import SwiftUI
import StoreKit

struct StorefrontView: View {
    @EnvironmentObject var storeKitManager: StoreKitManager
    @Environment(\.colorScheme) var colorScheme
    
    private var filteredProducts: [Product] {
        storeKitManager.storeStatus.storeProducts
            .sorted(by: { $0.displayName < $1.displayName })
            .filter { product in
                [StoreKitManager.creditsProductId, StoreKitManager.premiumProductId].contains(product.id)
            }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                Text("Search Credits")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 12) {
                    Text("Each search uses 1 credit to discover coffee shops and breweries near you.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    Text("💡 Tip: Watch ads to earn free credits!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                // Store Products
                VStack(alignment: .leading) {
                    Text("Store")
                        .bold()
                        .padding(.bottom, 10)
                    
                    ForEach(filteredProducts) { product in
                        ProductItem(storeKit: storeKitManager, product: product)
                    }
                    .cardStyle()
                    
                    HStack {
                        Spacer()
                        Button("Restore Purchases") {
                            Task {
                                try? await AppStore.sync()
                            }
                        }
                        .buttonStyle(ProfessionalButtonStyle())
                        Spacer()
                    }
                    .padding(.top, 20)
                }
                .padding()
                .cornerRadius(10)
                .shadow(radius: 5)
                .onReceive(storeKitManager.$storeStatus) { _ in }
                
                Spacer()
            }
        }
    }
}

struct ProductItem: View {
    @ObservedObject var storeKit: StoreKitManager
    @State private var isPurchasing: Bool = false
    
    var product: Product
    let BUTTON_COLOR = Color("#947329")
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: purchaseAction) {
            HStack {
                productTitle
                Spacer()
                purchaseOrBoughtView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .background(BUTTON_COLOR)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    private var productTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.displayName)
                .foregroundColor(Color("#ffffff"))
                .font(.headline)
            Text(getProductDescription())
                .foregroundColor(Color("#ffffff").opacity(0.8))
                .font(.caption)
        }
    }
    
    private var purchaseOrBoughtView: some View {
        Group {
            if storeKit.storeStatus.isPremiumPurchased && product.id == StoreKitManager.premiumProductId {
                purchasedLabel
            } else if isPurchasing {
                ProgressView()
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
        guard !isPurchasing else { return }
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
    
    private func getProductDescription() -> String {
        switch product.id {
        case StoreKitManager.creditsProductId:
            return "5 search credits - Discover more coffee shops and breweries"
        case StoreKitManager.premiumProductId:
            return "50 search credits + Remove ads + Unlimited favorites"
        default:
            return product.description
        }
    }
}

// MARK: - Custom Button Style
struct ProfessionalButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

// MARK: - Card Style Modifier
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
    StorefrontView()
        .environmentObject(StoreKitManager())
}
