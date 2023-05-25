//
//  FavoriteView.swift
//  Brewies
//
//  Created by Noah Boyers on 5/12/23.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var coffeeShopData = CoffeeShopData.shared
    @Binding var showPreview: Bool
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(coffeeShopData.favoriteShops, id: \.id) { coffeeShop in
                        NavigationLink(destination: BrewDetailView(coffeeShop: coffeeShop)) {
                            BrewPreview(coffeeShop: coffeeShop, showBrewPreview: $showPreview)
                        }
                    }
                }
                .padding(.all, 16)
            }
            .navigationTitle("Favorites")
        }
    }
}

