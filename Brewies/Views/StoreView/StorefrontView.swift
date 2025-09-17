//
//  StorefrontView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/6/23.
//

import SwiftUI
import StoreKit

struct StorefrontView: View {
    @StateObject var storeKitManager = StoreKitManager()
    @StateObject var userVM = UserViewModel.shared
    @Environment(\.presentationMode) var presentationMode
    
    let features = [
        ("magnifyingglass", "Unlimited Searches", "Search as many locations as you want"),
        ("slider.horizontal.3", "Advanced Filters", "Filter by cuisine, amenities, and more"),
        ("phone", "Business Details", "Get hours, phone numbers, and websites"),
        ("heart.fill", "Unlimited Favorites", "Save as many locations as you like"),
        ("map", "Offline Maps", "Download areas for offline access"),
        ("bell.badge", "No Advertisements", "Enjoy an ad-free experience")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                        
                        Text("Upgrade to Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Unlock the full potential of location discovery")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)
                    
                    // Features Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 20) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            VStack(spacing: 12) {
                                Image(systemName: feature.0)
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(width: 56, height: 56)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                                
                                VStack(spacing: 4) {
                                    Text(feature.1)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text(feature.2)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Credits Section
                    VStack(spacing: 16) {
                        Text("Buy Search Credits")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Purchase individual credits for searching locations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                            CreditPackCard(credits: 10, price: "$0.99", storeKitManager: storeKitManager)
                            CreditPackCard(credits: 25, price: "$1.99", storeKitManager: storeKitManager, isPopular: true)
                            CreditPackCard(credits: 50, price: "$2.99", storeKitManager: storeKitManager)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Subscription Plans
                    VStack(spacing: 16) {
                        Text("Unlimited Plans")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Get unlimited searches plus premium features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            // Monthly Plan
                            if let monthlyProduct = storeKitManager.storeStatus.storeProducts.first(where: { $0.id == StoreKitManager.monthlyID }) {
                                PricingCard(
                                    title: "Monthly",
                                    price: monthlyProduct.displayPrice,
                                    period: "per month",
                                    isPopular: false,
                                    product: monthlyProduct,
                                    storeKitManager: storeKitManager
                                )
                            }
                            
                            // Annual Plan
                            if let yearlyProduct = storeKitManager.storeStatus.storeProducts.first(where: { $0.id == StoreKitManager.yearlyID }) {
                                PricingCard(
                                    title: "Annual",
                                    price: yearlyProduct.displayPrice,
                                    period: "per year",
                                    isPopular: true,
                                    product: yearlyProduct,
                                    storeKitManager: storeKitManager
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Terms
                    VStack(spacing: 8) {
                        Text("7-day free trial, cancel anytime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            Button("Terms of Service") {
                                // Handle terms
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            
                            Button("Privacy Policy") {
                                // Handle privacy
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            
                            Button("Restore Purchases") {
                                Task {
                                    try? await AppStore.sync()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct CreditPackCard: View {
    let credits: Int
    let price: String
    let storeKitManager: StoreKitManager
    let isPopular: Bool
    
    init(credits: Int, price: String, storeKitManager: StoreKitManager, isPopular: Bool = false) {
        self.credits = credits
        self.price = price
        self.storeKitManager = storeKitManager
        self.isPopular = isPopular
    }
    
    @StateObject var userVM = UserViewModel.shared
    
    var body: some View {
        VStack(spacing: 12) {
            if isPopular {
                Text("Best Value")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .clipShape(Capsule())
            }
            
            VStack(spacing: 4) {
                Text("\(credits)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("credits")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(price)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            Button(action: {
                // Handle credit purchase
                userVM.addCredits(credits)
            }) {
                Text("Buy")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPopular ? Color.green : Color(UIColor.separator), lineWidth: isPopular ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    let isPopular: Bool
    let product: Product
    let storeKitManager: StoreKitManager
    
    @StateObject var userVM = UserViewModel.shared
    
    var body: some View {
        VStack(spacing: 16) {
            if isPopular {
                Text("Most Popular")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(price)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(period)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isPopular {
                    Text("Save 30%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            Button(action: {
                Task {
                    try? await storeKitManager.purchase(product)
                }
            }) {
                Text("Start Free Trial")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPopular ? Color.blue : Color(UIColor.separator), lineWidth: isPopular ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}


#Preview {
    StorefrontView()
}
