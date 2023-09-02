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
    @State private var showAlert = false

    @State var showStorefront = false
    
    @ObservedObject var userViewModel = UserViewModel.shared
    
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
    let BUTTON_WIDTH: CGFloat = 175
    let BUTTON_HEIGHT: CGFloat = 15
    @Binding var showBrewPreview: Bool
    @ObservedObject var coffeeShopData = CoffeeShopData.shared
    @ObservedObject var userViewModel = UserViewModel.shared
    
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme (dark or light mode)
    
    @State private var isDetailShowing: Bool = false
    @State var showStorefront = false
    @State private var favoriteSlotsUsed = 0
    @State private var showAlert = false

    
    var isFavorite: Bool { userViewModel.user.favorites.contains(coffeeShop) }
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geo in
                ZStack {
                    HStack {
                        ForEach(coffeeShop.displayImageUrls, id: \.self) { imageUrl in
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
                    
                    if coffeeShop.photos.count > 3 {
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
                            .lineLimit(nil)  // Allows text to wrap to the next line
                            .fixedSize(horizontal: false, vertical: true) // Properly wraps text inside a ScrollView

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
                    HStack(spacing: 1) {
                        Text("\(coffeeShop.city), \(coffeeShop.state)")
                        Text((coffeeShop.price != nil ? "• \(coffeeShop.price!)" : ""))
                        Spacer()
                    }
                    .foregroundColor(.gray)
                    .font(.caption)
                    Text(coffeeShop.displayPhone.isEmpty ? "Phone number unavailable" : coffeeShop.displayPhone)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
//                      TODO: This will be a later update...maybe
//                    HStack { // Center the buttons to the middle
//                        Spacer()
//                        if coffeeShop.transactions.contains("delivery") || coffeeShop.transactions.contains("pickup") {
//                            Button(action: {
//                                // Stub functionality for mobile order
//                                print("Mobile Order UI")
//
//                            }) {
//                                Text("Mobile Order")
//                                    .frame(width: BUTTON_WIDTH, height: BUTTON_HEIGHT)
//                                    .font(.headline)
//                                    .foregroundColor(.white)
//                                    .padding()
//                                    .background(Color.blue)
//                                    .cornerRadius(10)
//                            }
//                        } else {
//                            Button(action: {
//                                // Stub functionality for calling
//                                print("Calling....")
//
//                            }) {
//                                HStack {
//                                    Image(systemName: "phone.circle")
//                                    Text("Call")
//                                }
//                                .frame(width: BUTTON_WIDTH, height: BUTTON_HEIGHT)
//                                .font(.headline)
//                                .foregroundColor(.white)
//                                .padding()
//                                .background(Color.black)
//                                .cornerRadius(10)
//                            }
//                        }
//                        Spacer()
//                    }
                }
            }
            .fullScreenCover(isPresented: $isDetailShowing) {
                BrewDetailView(coffeeShop: coffeeShop)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Maximum Favorites Reached"),
                    message: Text("You've reached the maximum number of favorite slots. You can watch ads in the Favorites Tab to earn more slots, purchase more in the Store, or subscribe to get 20 slots included."),
                    primaryButton: .default(Text("Go to Store"), action: {
                        // Set the state variable to true, to show the StorefrontView
                        showStorefront = true
                    }),
                    secondaryButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showStorefront) {
                StorefrontView()
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
            userViewModel.removeFromFavorites(coffeeShop)
            coffeeShopData.removeFromFavorites(coffeeShop)
            // Decrement favoriteSlotsUsed
            favoriteSlotsUsed -= 1
        } else {
            // Check if adding a new favorite would exceed the maximum allowed
            if coffeeShopData.addToFavorites(coffeeShop) {
                userViewModel.addToFavorites(coffeeShop)
                // Increment favoriteSlotsUsed
                favoriteSlotsUsed += 1
            } else {
                showAlert = true  // Show an alert
            }
        }
    }

}
