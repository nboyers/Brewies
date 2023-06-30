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
    var coffeeShop: CoffeeShop
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showSafariView = false
    @State private var showHoursSheet = false
    @State private var bottomSheetPosition: BottomSheetPosition = .relative(0.0) // Starting position for bottomSheet
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme (dark or light mode)
    
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
                            
                            RatingView(rating: coffeeShop.rating)
                            
                            
                        }
                    }
                    
                    VStack {
                        //MARK: Photos
                        VStack(alignment: .leading) {
                            
                            Text("Photos")
                                .padding(.horizontal)
                                .foregroundColor(.white)
                                .bold()
                                .font(.title)
                                .shadow(color: .black, radius: 3, x: 0, y: 0)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    if coffeeShop.photos.isEmpty {
                                        
                                        ForEach(0..<3) {_ in
                                            ZStack {
                                                Rectangle()
                                                    .foregroundColor(.gray)
                                                    .frame(width: geo.size.width/2, height: geo.size.height*0.25)
                                                    .cornerRadius(25)
                                                Image(systemName: "photo")
                                                    .resizable()
                                                    .foregroundColor(Color.white)
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 50, height: 50)
                                                    .clipped()
                                                    .cornerRadius(10)
                                                    .padding(.horizontal)
                                            }
                                        }
                                    } else {
                                        ForEach(coffeeShop.photos.prefix(3), id: \.self) { imageUrl in
                                            KFImage(URL(string: imageUrl))
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: geo.size.width/2, height: geo.size.height*0.25)
                                                .clipped()
                                                .cornerRadius(10)
                                                .padding(.horizontal)
                                        }
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
                                SmallMap(coordinate: CLLocationCoordinate2D ( latitude: coffeeShop.latitude,
                                                                              longitude: coffeeShop.longitude
                                                                            ), name: coffeeShop.name)
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
                                    .font(.title2)
                                    .bold()
                                    .padding(.horizontal)
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                Spacer()
                            }
                            
                            
                            VStack(alignment: .leading) {
                                //MARK: Hours are currently out of Service
                                HStack(alignment: .firstTextBaseline){
                                    VStack(alignment: .leading) {
                                        Text("Price \(coffeeShop.price ?? "is not listed")")
                                    }
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(2)
                                    .padding()
                                    Spacer()
                                }
    
                                Divider()
                                
                                // Phone
                                
                                Button(action: {
                                    callCoffeeShop()
                                }) {
                                    HStack {
                                        Text(coffeeShop.displayPhone.isEmpty ? "No phone number available" : coffeeShop.displayPhone)
                                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                        Spacer()
                                        
                                        Image(systemName: "phone.connection")
                                            .resizable()
                                            .frame(width: geo.size.width*0.05, height: geo.size.width*0.05)
                                            .foregroundColor(Color.accentColor)
                                    }
                                }
                                .padding()
                                
                                Divider()
                                
                                // Website
                                Button(action: {
                                    openCoffeeShopWebsite()
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
                                
                                
                                // Mobile Oder
                                //TODO: Create this
                                
                            }
                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                            .background(.bar)
                            .cornerRadius(15)
                            .frame(width: geo.size.width, height: geo.size.height*0.25)
                            
                            
                        }
                        
                    }
                }
            }
            .fullScreenCover(isPresented: $showSafariView) {
                if let url = URL(string: coffeeShop.url) {
                    SafariView(url: url)
                }
            }
            
            .navigationBarItems(trailing: closeButton)
        }
        .edgesIgnoringSafeArea(.top)
    }
    
    private var closeButton: some View {
        Button("Close") {
            self.presentationMode.wrappedValue.dismiss()
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
    
    private func openCoffeeShopWebsite() {
        showSafariView = true
    }
    private func dayOfTheWeek(_ day: Int) -> String {
        switch day {
        case 0: return "Monday"
        case 1: return "Tuesday"
        case 2: return "Wednesday"
        case 3: return "Thursday"
        case 4: return "Friday"
        case 5: return "Saturday"
        case 6: return "Sunday"
        default: return "Unknown day"
        }
    }
    private func formattedHours(_ hours: YelpOpenHours) -> String {
        let startHour = timeFormat(hours.start )
        let endHour = timeFormat(hours.end )
        return "\(startHour) - \(endHour)"
    }
    
    private func timeFormat(_ time: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HHmm"
        
        if let date = dateFormatter.date(from: time) {
            dateFormatter.dateFormat = "h:mm a"
            return dateFormatter.string(from: date)
        } else {
            return "Unknown time"
        }
    }
}
