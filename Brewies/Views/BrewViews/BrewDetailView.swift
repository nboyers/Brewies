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
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ZStack(alignment: .topLeading) {
                    //MARK: Header image
                    KFImage(URL(string: coffeeShop.imageURL))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                    
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
                }.edgesIgnoringSafeArea(.top)
                
                VStack {
                    Spacer()
                    VStack(alignment: .leading) {
                        //MARK: Coffee shop name
                        Text(coffeeShop.name)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.white)
                            .bold()
                            .font(.largeTitle)
                            .lineLimit(2)
                            .shadow(color: .black, radius: 3, x: 0, y: 0)
                        
                        //MARK: Rating and Review Count
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("\(coffeeShop.rating, specifier: "%.1f") (\(coffeeShop.reviewCount) reviews)")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .bold()
                    }
                    .padding(.horizontal)
                }
                //MARK: Photos
                VStack(alignment: .leading) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            if coffeeShop.photos.isEmpty {
                                ForEach(0..<3) {_ in
                                    ZStack {
                                        Rectangle()
                                            .foregroundColor(.gray)
                                            .frame(width: 200, height: 200)
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
                                        .frame(width: 100, height: 100)
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
                }.padding(5)
                
                //MARK: Address and Map
                VStack() {
                    HStack {
                        Text("Address")
                            .foregroundColor(.white)
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        Spacer()
                        
                    }
                    VStack(alignment: .leading) {
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
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                                
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundColor(Color.accentColor)
                                    .padding(.trailing)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Divider()
                        
                        Button(action: {
                            openMapsAppWithDirections()
                        }) {
                            HStack {
                                Text("Get Directions")
                                    .font(.headline)
                                    .padding([.leading, .trailing, .bottom])
                                    .lineLimit(2)
                                Spacer()
                                Image(systemName: "location.circle")
                                    .padding(.trailing)
                                
                            }
                            .foregroundColor(Color.accentColor)
                            .padding(5)
                        }
                    }
                    .background(.bar)
                    .frame(width: 400, height: 300)
                    .cornerRadius(15)
                    .padding()
                    
                }
                HStack {
                    Image(systemName: "phone.circle")
                        .foregroundColor(.white)
                    Button(action: {
                        callCoffeeShop()
                    }) {
                        Text(coffeeShop.displayPhone)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                
                //MARK: Open Hours
                VStack(alignment: .leading, spacing: 5) {
                    
                    Button(action: {
                        showHoursSheet = true
                    }) {
                        Text("See all hours ->")
                            .foregroundColor(.white)
                    }
                    
                    // "Visit website" button
                    Button(action: {
                        openCoffeeShopWebsite()
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Visit website")
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    
                    
                    .sheet(isPresented: $showHoursSheet) {
                        VStack(spacing: 10) {
                            HStack(spacing: 50) {
                                Text("Hours")
                                    .font(.largeTitle)
                                Image(systemName: "xmark")
                                    .onTapGesture {
                                        showHoursSheet = false
                                    }
                            }
                            .foregroundColor(Color(UIColor.systemBackground))
                            
                            if let shopHours = coffeeShop.hours?.first?.open {
                                ForEach(shopHours, id: \.day) { openHour in
                                    HStack {
                                        Text(dayOfTheWeek(openHour.day))
                                            .font(.largeTitle)
                                        Spacer()
                                        Text(formattedHours(openHour))
                                            .font(.title2)
                                    }
                                }
                                .foregroundColor(Color(UIColor.systemBackground))
                            } else {
                                Text("Something broke LOL")
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .presentationDetents([.medium, .large])
                    }
                    
                    
                    .fullScreenCover(isPresented: $showSafariView) {
                        if let url = URL(string: coffeeShop.url) {
                            SafariView(url: url)
                        }
                    }
                    .padding()
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
        let startHour = timeFormat(hours.start)
        let endHour = timeFormat(hours.end)
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
