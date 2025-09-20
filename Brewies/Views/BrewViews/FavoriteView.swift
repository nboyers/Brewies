//
//  FavoriteView.swift
//  Brewies
//
//  Created by Noah Boyers on 5/12/23.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var selectedCoffeeShop: SelectedCoffeeShop
    @ObservedObject var coffeeShopData = CoffeeShopData.shared
    @ObservedObject var storeKit = StoreKitManager()
    
    @Binding var showPreview: Bool
    @Binding var activeSheet: ActiveSheet?
    
    @State private var searchText = ""
    @State private var showRemovalConfirmationAlert = false
    @State private var toRemoveCoffeeShop: BrewLocation?
    
    private var filteredFavorites: [BrewLocation] {
        if searchText.isEmpty {
            return coffeeShopData.favoriteShops
        } else {
            return coffeeShopData.favoriteShops.filter { shop in
                shop.name.localizedCaseInsensitiveContains(searchText) ||
                (shop.address?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Favorites")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("\(coffeeShopData.favoriteShops.count) saved locations")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search favorites...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Content
                if filteredFavorites.isEmpty {
                    emptyStateView
                } else {
                    favoritesList
                }
                
                // Ad banner
                if !storeKit.storeStatus.isPremiumPurchased {
                    AdBannerView()
                        .frame(height: 50)
                        .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
        }
        .alert(isPresented: $showRemovalConfirmationAlert) {
            Alert(
                title: Text("Remove Favorite"),
                message: Text("Remove this location from your favorites?"),
                primaryButton: .destructive(Text("Remove")) {
                    if let toRemove = toRemoveCoffeeShop {
                        coffeeShopData.removeFromFavorites(toRemove)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Favorites Yet" : "No Results")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(searchText.isEmpty ? 
                     "Start exploring and save your favorite coffee shops and breweries" :
                     "Try adjusting your search terms")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
    
    private var favoritesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredFavorites, id: \.id) { coffeeShop in
                    FavoriteItemView(
                        coffeeShop: coffeeShop,
                        onTap: {
                            selectedCoffeeShop.coffeeShop = coffeeShop
                            activeSheet = .detailBrew
                        },
                        onRemove: {
                            toRemoveCoffeeShop = coffeeShop
                            showRemovalConfirmationAlert = true
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

struct FavoriteItemView: View {
    let coffeeShop: BrewLocation
    let onTap: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Photo
                if !coffeeShop.id.isEmpty {
                    GooglePlacesPhotoView(placeID: coffeeShop.id)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "cup.and.saucer.fill")
                                .foregroundColor(.secondary)
                        )
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(coffeeShop.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let address = coffeeShop.address {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    if let rating = coffeeShop.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Remove button
                Button(action: onRemove) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
