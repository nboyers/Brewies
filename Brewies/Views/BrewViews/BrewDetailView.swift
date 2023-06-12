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
 //MARK: Content Vjew
    var body: some View {
        ScrollView {
            content
                .navigationBarItems(trailing: closeButton)
        }
        .edgesIgnoringSafeArea(.top)
    }
    
    private var closeButton: some View {
        Button("Close") {
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    //MARK: content
    private var content: some View {
        VStack(alignment: .leading) {
            headerView
            VStack {
                photosView
                addressAndMapView
                phoneView
                websiteButton
            }
            .padding()
        }
        .edgesIgnoringSafeArea(.top)
    }
    //MARK: headerView
    private var headerView: some View {
        ZStack(alignment: .topLeading) {
            KFImage(URL(string: coffeeShop.imageURL))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 300)
                .clipped()
            Text(coffeeShop.name)
                .multilineTextAlignment(.leading)
                .foregroundColor(.white)
                .bold()
                .font(.title)
                .lineLimit(2)
                .shadow(color: .black, radius: 3, x: 0, y: 0)
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
        }
        .edgesIgnoringSafeArea(.top)
    }
    //MARK: PhotosView
    private var photosView: some View {
        VStack(alignment: .leading) {
            RatingView(rating: coffeeShop.rating)
                .foregroundColor(.yellow)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    if coffeeShop.photos.isEmpty {
                        ForEach(0..<3) { _ in
                            placeholderPhotoView
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
            
            if coffeeShop.photos.count > 3 {
                seeAllButton
            }
        }
        .padding(5)
    }
    
    //MARK: placeholderPhotoView
    private var placeholderPhotoView: some View {
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
    //MARK: seeAllButto
    private var seeAllButton: some View {
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
  //MARK: addressAndMapView
    private var addressAndMapView: some View {
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
                SmallMap(coordinate: CLLocationCoordinate2D(latitude: coffeeShop.latitude,
                                                            longitude: coffeeShop.longitude), name: coffeeShop.name)
                addressButton
                Divider()
                directionsButton
            }
            .background(.bar)
            .frame(width: 400, height: 300)
            .cornerRadius(15)
            .padding()
        }
    }
  //MARK: addressButton
    private var addressButton: some View {
        Button(action: {
            UIPasteboard.general.string = "\(coffeeShop.address)"
        }) {
            HStack {
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
    }
    //MARK: directionsButton
    private var directionsButton: some View {
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
    //MARK: Phone View
    private var phoneView: some View {
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
    }
    //MARK:  websiteButton
    private var websiteButton: some View {
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
    }
    //MARK: FUNCTIONS
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
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HHmm"
            return formatter
        }()
        
        if let date = dateFormatter.date(from: time) {
            dateFormatter.dateFormat = "h:mm a"
            return dateFormatter.string(from: date)
        } else {
            return "Unknown time"
        }
    }
}
