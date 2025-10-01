//
//  FavoriteView.swift
//  Brewies
//
//  Created by Noah Boyers on 5/12/23.
//

import SwiftUI
import AppTrackingTransparency

struct FavoritesView: View {
    @EnvironmentObject var contentVM: ContentViewModel
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var selectedCoffeeShop: SelectedCoffeeShop
    @StateObject var sharedAlertVM = SharedAlertViewModel()
    @ObservedObject var coffeeShopData = CoffeeShopData.shared
    
    @Binding var showPreview: Bool
    @State private var showRemovalConfirmationAlert = false
    @State private var toRemoveCoffeeShop: BrewLocation?
    @State private var searchText = ""
    
    @Binding var activeSheet: ActiveSheet?
    
    private var filteredFavorites: [BrewLocation] {
        if searchText.isEmpty {
            return userVM.user.favorites
        } else {
            return userVM.user.favorites.filter { shop in
                shop.name.localizedCaseInsensitiveContains(searchText) ||
                (shop.address?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search favorites...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Favorites List
                if filteredFavorites.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredFavorites, id: \.id) { coffeeShop in
                                FavoriteItemView(
                                    coffeeShop: coffeeShop,
                                    activeSheet: $activeSheet,
                                    showPreview: $showPreview,
                                    onRemove: {
                                        toRemoveCoffeeShop = coffeeShop
                                        showRemovalConfirmationAlert = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        if !userVM.user.isPremium {
                            AdBannerView()
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .padding(.top, 16)
                        }
                    }
                }
            }
            .navigationTitle(favoritesTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !userVM.user.favorites.isEmpty {
                        Button("Clear All") {
                            showClearAllAlert()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert(isPresented: $showRemovalConfirmationAlert) {
                Alert(
                    title: Text("Remove Favorite"),
                    message: Text("Remove \"\(toRemoveCoffeeShop?.name ?? "this location")\" from your favorites?"),
                    primaryButton: .destructive(Text("Remove")) {
                        if let toRemove = toRemoveCoffeeShop {
                            userVM.removeFromFavorites(toRemove)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var favoritesTitle: String {
        let count = userVM.user.favorites.count
        if userVM.user.isPremium {
            return "Favorites (\(count))"
        } else {
            return "Favorites (\(count)/\(userVM.favoritesLimit))"
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Favorites Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Discover coffee shops and breweries, then tap the heart icon to save them here.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
    
    private func showClearAllAlert() {
        let alert = UIAlertController(
            title: "Clear All Favorites",
            message: "This will remove all \(userVM.user.favorites.count) favorites. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { _ in
            userVM.user.favorites.removeAll()
            userVM.saveFavorites()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

struct FavoriteItemView: View {
    let coffeeShop: BrewLocation
    @Binding var activeSheet: ActiveSheet?
    @Binding var showPreview: Bool
    let onRemove: () -> Void
    
    var body: some View {
        NavigationLink(destination: BrewDetailView(coffeeShop: coffeeShop)) {
            BrewListItem(location: coffeeShop, photoIndex: 0, activeSheet: $activeSheet)
        }
        .contextMenu {
            Button(action: onRemove) {
                Label("Remove from Favorites", systemImage: "heart.slash")
            }
            
            Button(action: {
                shareLocation(coffeeShop)
            }) {
                Label("Share Location", systemImage: "square.and.arrow.up")
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func shareLocation(_ location: BrewLocation) {
        let text = "Check out \(location.name)" + (location.address != nil ? " at \(location.address!)" : "")
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}
