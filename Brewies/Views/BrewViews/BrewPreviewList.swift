//
//  BrewPreviewList.swift
//  Brewies
//
//  Created by Noah Boyers on 5/9/23.
//

import SwiftUI
import Kingfisher

struct BrewPreviewList: View {
    @Binding var coffeeShops: [CoffeeShop]
    @Binding var selectedCoffeeShop: CoffeeShop?
    @Binding var showBrewPreview: Bool
    
    var body: some View {
        ScrollViewReader { scrollView in
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(coffeeShops) { coffeeShop in
                            BrewPreview(coffeeShop: coffeeShop, showBrewPreview: $showBrewPreview)
                                .id(coffeeShop.id)
                        }
                    }
                    .padding([.top, .horizontal])
                }
                .onChange(of: selectedCoffeeShop) { coffeeShop in
                    if let coffeeShop = coffeeShop {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            scrollView.scrollTo(coffeeShop.id, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}

struct BrewPreview: View {
    let coffeeShop: CoffeeShop
    @Binding var showBrewPreview: Bool
    @ObservedObject var coffeeShopData = CoffeeShopData.shared
    
    @State private var isDetailShowing: Bool = false
    
    
    var isFavorite: Bool {
        coffeeShopData.favoriteShops.contains(coffeeShop)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geo in
                ZStack {
                    HStack {
                        ForEach(coffeeShop.displayImageUrls.prefix(3), id: \.self) { imageUrl in
                            if !imageUrl.isEmpty {
                                KFImage(URL(string: imageUrl))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width * 0.9, height: geo.size.height * 0.66)
                                    .clipped()
                            } else {
                                Text("Image not available")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height / 2)
                    .clipped()
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    
                    if coffeeShop.displayImageUrls.count > 3 {
                        VStack {
                            HStack {
                                Spacer()
                                Text("See all")
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .foregroundColor(.white)
                                    .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                                    .cornerRadius(8)
                            }
                            Spacer()
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Spacer()
                        .frame(height: geo.size.height / 2)
                    HStack {
                        Text(coffeeShop.name)
                            .font(.headline)
                            .foregroundColor(Color.black)
                        Spacer()
                        
                        Button(action: {
                            toggleFavorite()
                        }) {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .resizable()
                                .foregroundColor(.yellow)
                                .frame(width: 30, height: 30)
                                .padding(5)
                        }
                    }
                    
                    Text(coffeeShop.address)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(coffeeShop.phone)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    //FIXME: This get's cached to whatever time the user first searched making it not correct all the time
                    Text(coffeeShop.isOpen ? "Open" : "Closed")
                        .font(.caption)
                        .foregroundColor(coffeeShop.isOpen ? .green : .red)
                }
                
            }
            .fullScreenCover(isPresented: $isDetailShowing) {
                BrewDetailView(coffeeShop: coffeeShop)
            }
            .onTapGesture {
                isDetailShowing = true
            }
            .padding()
        }
        .frame(width: 300, height: 300)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 4)
    }
    private func toggleFavorite() {
        if isFavorite {
            coffeeShopData.removeFromFavorites(coffeeShop)
        } else {
            coffeeShopData.addToFavorites(coffeeShop)
        }
    }
}
