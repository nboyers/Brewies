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

//    var isOpen: Bool {
//        guard let todayDay = Calendar.current.dateComponents([.weekday], from: Date()).weekday, todayDay >= 1, todayDay <= 7 else {
//            // If we can't get the current day, return false
//            return false
//        }
//        // Adjust the index to match the Calendar API where Sunday = 1
//        let todayIndex = todayDay == 1 ? 6 : todayDay - 2
//
//        let currentTime = Calendar.current.dateComponents([.hour, .minute], from: Date())
//
//        // Find the open hours for today
//        for hours in coffeeShop.hours ?? [] {
//            for openHours in hours.open {
//                if openHours.day == todayIndex {
//                    guard let startTime = Date.fromTime(openHours.start),
//                          let endTime = Date.fromTime(openHours.end) else {
//                        return false
//                    }
//
//                    let startComponents = Calendar.current.dateComponents([.hour, .minute], from: startTime)
//                    let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endTime)
//
//                    if let startHour = startComponents.hour, let startMinute = startComponents.minute,
//                       let endHour = endComponents.hour, let endMinute = endComponents.minute,
//                       let currentHour = currentTime.hour, let currentMinute = currentTime.minute {
//                        if startHour < endHour || (startHour == endHour && startMinute <= endMinute) {
//                            return currentHour > startHour && currentHour < endHour
//                                || (currentHour == startHour && currentMinute >= startMinute)
//                                || (currentHour == endHour && currentMinute <= endMinute)
//                        } else { // for cases where the shop is open overnight
//                            return currentHour > startHour
//                                || (currentHour == startHour && currentMinute >= startMinute)
//                                || currentHour < endHour
//                                || (currentHour == endHour && currentMinute <= endMinute)
//                        }
//                    }
//                }
//            }
//        }
//        return false
//    }

    
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
                    
                    Text("\(coffeeShop.city), \(coffeeShop.state)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(coffeeShop.displayPhone)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(!coffeeShop.isClosed ? "OPEN" : "CLOSED")
                        .font(.caption)
                        .foregroundColor(!coffeeShop.isClosed ? .green : .red)

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
