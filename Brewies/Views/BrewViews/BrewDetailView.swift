//
//  BrewDetailView.swift
//  Brewies
//
//  Created by Noah Boyers on 5/15/23.
//


import SwiftUI
import SafariServices
import BottomSheet
import Kingfisher
import CoreLocation
import MapKit


struct BrewDetailView: View {
    var coffeeShop: BrewLocation
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showSafariView = false
    @State private var showHoursSheet = false
    @State private var bottomSheetPosition: BottomSheetPosition = .relative(0.0) // Starting position for bottomSheet
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme (dark or light mode)
    @State private var activeSheet: ActiveSheet?
    
    @EnvironmentObject var selectedCoffeeShop: SelectedCoffeeShop
    
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading) {
                    ZStack(alignment: .topLeading) {
                        //MARK: Header image
                        KFImage(URL(string: coffeeShop.imageURL))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: geo.size.height*0.4)
                            .clipped()
                            .edgesIgnoringSafeArea(.top)
                        // Dismiss Button
                        Button(action: {
                            activeSheet = nil
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "arrow.uturn.left")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.red.opacity(0.6))
                                .clipShape(Circle())
                                .padding(.top, 50)
                                .padding(.leading, 20)
                        }
                        VStack(alignment: .leading) {
                            Spacer()
                            //MARK: Coffee shop name
                            Text(coffeeShop.name)
                                .padding(.horizontal)
                                .foregroundColor(.white)
                                .bold()
                                .font(.title)
                                .shadow(color: .black, radius: 3, x: 0, y: 0)
                        }
                    }
                    
                    VStack {
                        //MARK: Photos
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                RatingView(rating: coffeeShop.rating, review_count: String(coffeeShop.review_count), colorScheme: colorScheme == .dark ? .white : .black)
                                    .padding(.horizontal)
                                Image("yelp")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                Spacer()
                            }
                            
                            if !coffeeShop.photos.isEmpty {
                                Text("Photos")
                                    .padding(.horizontal)
                                    .foregroundColor(.white)
                                    .bold()
                                    .font(.title)
                                    .shadow(color: .black, radius: 3, x: 0, y: 0)
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    if !coffeeShop.photos.isEmpty {
                                        ForEach(coffeeShop.photos.prefix(3), id: \.self) { imageUrl in
                                            KFImage(URL(string: imageUrl))
                                                .resizable()
                                                .foregroundColor(Color.white)
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 50, height: 50)
                                                .clipped()
                                                .cornerRadius(10)
                                                .padding(.horizontal)
                                        }
//                                        
//                                        ForEach(0..<3) {_ in
//                                            ZStack {
//                                                Rectangle()
//                                                    .foregroundColor(.gray)
//                                                    .frame(width: geo.size.width/2, height: geo.size.height*0.25)
//                                                    .cornerRadius(25)
//                                                Image(systemName: "photo")
//                                                    .resizable()
//                                                    .foregroundColor(Color.white)
//                                                    .aspectRatio(contentMode: .fit)
//                                                    .frame(width: 50, height: 50)
//                                                    .clipped()
//                                                    .cornerRadius(10)
//                                                    .padding(.horizontal)
//                                            }
//                                        }
                                    }
                                }
                            }
                            
                            // "See all" button
                            if coffeeShop.photos.count > 3 {
                                NavigationLink(destination: PhotosView(photoUrls: Array(coffeeShop.photos.dropFirst(3)))) {
                                    HStack {
                                        Spacer()
                                        Text("See all")
                                        Spacer()
                                    }
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(5)
                        
                        //MARK: Map
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Address")
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                    .font(.title2)
                                    .bold()
                                    .padding(.horizontal)
                                Spacer()
                                
                            }
                            
                            VStack(alignment: .center) {
                                
                                Button(action: {
                                    openMapsAppWithDirections()
                                }) {
                                    HStack {
                                        SmallMap(coordinate: CLLocationCoordinate2D ( latitude: coffeeShop.latitude,
                                                                                      longitude: coffeeShop.longitude
                                                                                    ), name: coffeeShop.name)
                                    }
                                }
                                
                                Button(action: {
                                    UIPasteboard.general.string = "\(coffeeShop.address)"
                                }) {
                                    HStack() {
                                        Text("\(coffeeShop.address)")
                                            .padding([.leading, .trailing, .bottom, .top])
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        
                                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "doc.on.doc.fill")
                                            .resizable()
                                            .frame(width: geo.size.width*0.05, height: geo.size.width*0.05)
                                            .foregroundColor(Color.accentColor)
                                        
                                    }
                                }
                                .padding()
                                
                                Divider()
                                Button(action: {
                                    openMapsAppWithDirections()
                                }) {
                                    HStack {
                                        Text("Get Directions")
                                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                            .padding([.leading, .trailing, .bottom])
                                            .lineLimit(2)
                                        Spacer()
                                        
                                        Image(systemName: "location.circle")
                                            .resizable()
                                            .foregroundColor(Color.accentColor)
                                            .frame(width: geo.size.width*0.05, height: geo.size.width*0.05)
                                        
                                    }
                                    .padding()
                                }
                            }
                            .background(.bar)
                            .frame(width: geo.size.width, height: geo.size.height*0.40)
                            .cornerRadius(15)
                            
                        }
                        
                        //MARK: DETAILS
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Details")
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                    .font(.title2)
                                    .bold()
                                    .padding(.horizontal)
                                Spacer()
                            }
                            
                            VStack(alignment: .leading) {
                                //MARK: Website
                                Button(action: {
                                    showSafariView = true
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Website")
                                                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                        }
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right.square")
                                            .resizable()
                                            .frame(width: geo.size.width*0.05, height: geo.size.width*0.05)
                                            .foregroundColor(Color.accentColor)
                                    }
                                }
                                .padding()
                                
                                Divider()
                                
                                HStack(alignment: .firstTextBaseline){
                                    VStack(alignment: .leading) {
                                        Text("Price: \(convertYelpPriceToRange(yelpPrice: coffeeShop.price ?? "is not listed"))")
                                    }
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(2)
                                    .padding()
                                    Spacer()
                                }
                                
                                Divider()
                                
                                //MARK: Phone
                                
                                Button(action: {
                                    callCoffeeShop()
                                }) {
                                    HStack {
                                        Text(coffeeShop.displayPhone.isEmpty ? "Phone number unavailable" : coffeeShop.displayPhone)
                                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                        Spacer()
                                        
                                        Image(systemName: "phone.connection")
                                            .resizable()
                                            .frame(width: geo.size.width*0.05, height: geo.size.width*0.05)
                                            .foregroundColor(Color.accentColor)
                                    }
                                }
                                .padding()
                            }
                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                            .background(.bar)
                            .cornerRadius(15)
                            .frame(width: geo.size.width, height: geo.size.height*0.25)
                            
                        }
                        
                    }
                }
            }
            .sheet(isPresented: $showSafariView) {
                if let url = URL(string: selectedCoffeeShop.coffeeShop?.url ?? "nobosoftware.com") {
                    SafariView(url: url)
                }
            }
            
            .edgesIgnoringSafeArea(.top)
        }
    }
    
    private func convertYelpPriceToRange(yelpPrice: String) -> String {
        switch yelpPrice {
        case "$":
            return "Under $10"
        case "$$":
            return "$11 - $30"
        case "$$$":
            return "$31 - $60"
        case "$$$$":
            return "Over $61"
        default:
            return "Unknown price range"  // Handle unknown or unexpected input
        }
    }
    
    private func openMapsAppWithDirections() {
        let destination = "\(coffeeShop.latitude),\(coffeeShop.longitude)"
        let formattedDestination = destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = "http://maps.apple.com/?daddr=\(formattedDestination)"
        if let url = URL(string: url), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func callCoffeeShop() {
        let phoneNumber = coffeeShop.displayPhone
        if let url = URL(string: "tel://\(phoneNumber)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
}
