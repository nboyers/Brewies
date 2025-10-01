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
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        VStack(spacing: 8) {
                            Text("Search Credits")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text("Discover amazing coffee shops and breweries")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Info Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("How it works")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Text("1")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Circle().fill(.blue))
                                Text("Each search uses 1 credit")
                                    .font(.subheadline)
                                Spacer()
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                Text("2")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Circle().fill(.blue))
                                Text("Watch ads to earn free credits")
                                    .font(.subheadline)
                                Spacer()
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                Text("3")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Circle().fill(.blue))
                                Text("Discover local favorites near you")
                                    .font(.subheadline)
                                Spacer()
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    
                    // Products Section
                    VStack(spacing: 20) {
                        HStack {
                            Text("Purchase Options")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        LazyVStack(spacing: 16) {
                            ForEach(filteredProducts) { product in
                                ProductItem(storeKit: storeKitManager, product: product)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Restore Purchases
                    Button("Restore Purchases") {
                        Task {
                            try? await AppStore.sync()
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Store")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onReceive(storeKitManager.$storeStatus) { _ in }
    }
}

struct ProductItem: View {
    @ObservedObject var storeKit: StoreKitManager
    @State private var isPurchasing: Bool = false
    
    var product: Product
    @Environment(\.colorScheme) var colorScheme
    
    private var isPremium: Bool {
        product.id == StoreKitManager.premiumProductId
    }
    
    private var isPurchased: Bool {
        storeKit.storeStatus.isPremiumPurchased && isPremium
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Premium Badge
            if isPremium {
                HStack {
                    Spacer()
                    Text("MOST POPULAR")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.orange)
                        )
                    Spacer()
                }
                .padding(.top, -8)
                .zIndex(1)
            }
            
            // Main Card
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: isPremium ? "crown.fill" : "creditcard.fill")
                            .font(.title2)
                            .foregroundColor(isPremium ? .orange : .blue)
                        
                        Text(product.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text(getProductDescription())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
                
                // Features
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(getFeatures(), id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                
                // Purchase Button
                Button(action: purchaseAction) {
                    HStack {
                        if isPurchased {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Purchased")
                                .fontWeight(.semibold)
                        } else if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("Processing...")
                                .fontWeight(.semibold)
                        } else {
                            Text("Purchase for \(product.displayPrice)")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isPurchased ? Color.green.opacity(0.2) : (isPremium ? Color.orange : Color.blue))
                    )
                    .foregroundColor(isPurchased ? .green : .white)
                }
                .disabled(isPurchased || isPurchasing)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                    .stroke(isPremium ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 2)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    private func purchaseAction() {
        guard !isPurchasing && !isPurchased else { return }
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
            return "Perfect for occasional searches"
        case StoreKitManager.premiumProductId:
            return "Best value with premium features"
        default:
            return product.description
        }
    }
    
    private func getFeatures() -> [String] {
        switch product.id {
        case StoreKitManager.creditsProductId:
            return ["5 search credits", "Discover coffee shops", "Find local breweries"]
        case StoreKitManager.premiumProductId:
            return ["50 search credits", "Remove all ads", "Unlimited favorites"]
        default:
            return []
        }
    }
}

#Preview {
    StorefrontView()
        .environmentObject(StoreKitManager())
}
