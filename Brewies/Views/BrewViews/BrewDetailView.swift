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
                        // MARK: Header image
                        if let imageURL = buildGooglePhotoURL(photoReference: coffeeShop.photos?.first) {
                            KFImage(URL(string: imageURL))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.4)
                                .clipped()
                                .edgesIgnoringSafeArea(.top)
                        }
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
                            // MARK: Coffee shop name
                            Text(coffeeShop.name)
                                .padding(.horizontal)
                                .foregroundColor(.white)
                                .bold()
                                .font(.title)
                                .shadow(color: .black, radius: 3, x: 0, y: 0)
                        }
                    }

                    VStack {
                        // MARK: Rating and Photos
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                RatingView(rating: coffeeShop.rating ?? 0, review_count: String(coffeeShop.userRatingsTotal ?? 0), colorScheme: colorScheme == .dark ? .white : .black)
                                    .padding(.horizontal)
                                Spacer()
                            }

                            if let photos = coffeeShop.photos, !photos.isEmpty {
                                Text("Photos")
                                    .padding(.horizontal)
                                    .foregroundColor(.white)
                                    .bold()
                                    .font(.title)
                                    .shadow(color: .black, radius: 3, x: 0, y: 0)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(photos.prefix(3), id: \.self) { photoReference in
                                            if let imageURL = buildGooglePhotoURL(photoReference: photoReference) {
                                                KFImage(URL(string: imageURL))
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 50, height: 50)
                                                    .clipped()
                                                    .cornerRadius(10)
                                                    .padding(.horizontal)
                                            }
                                        }
                                    }
                                }

                                // "See all" button
                                if photos.count > 3 {
                                    NavigationLink(destination: PhotosView(photoUrls: Array(photos.dropFirst(3)).compactMap { buildGooglePhotoURL(photoReference: $0) })) {
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
                        }
                        .padding(5)

                        // MARK: Map
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
                                        SmallMap(coordinate: CLLocationCoordinate2D(latitude: coffeeShop.latitude, longitude: coffeeShop.longitude), name: coffeeShop.name)
                                    }
                                }

                                Button(action: {
                                    UIPasteboard.general.string = coffeeShop.address
                                }) {
                                    HStack {
                                        Text(coffeeShop.address ?? "Address not available")
                                            .padding([.leading, .trailing, .bottom, .top])
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer()
                                        Image(systemName: "doc.on.doc.fill")
                                            .resizable()
                                            .frame(width: geo.size.width * 0.05, height: geo.size.width * 0.05)
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
                                            .frame(width: geo.size.width * 0.05, height: geo.size.width * 0.05)
                                    }
                                    .padding()
                                }
                            }
                            .background(.bar)
                            .frame(width: geo.size.width, height: geo.size.height * 0.40)
                            .cornerRadius(15)
                        }

                        // MARK: Details
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
                                // MARK: Website
                                if coffeeShop.website != nil {
                                    Button(action: {
                                        showSafariView = true
                                    }) {
                                        HStack {
                                            Text("Website")
                                                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                            Spacer()
                                            Image(systemName: "arrow.up.right.square")
                                                .resizable()
                                                .frame(width: geo.size.width * 0.05, height: geo.size.width * 0.05)
                                                .foregroundColor(Color.accentColor)
                                        }
                                    }
                                    .padding()
                                    Divider()
                                }

                                // MARK: Price Level
                                if let priceLevel = coffeeShop.priceLevel {
                                    HStack(alignment: .firstTextBaseline) {
                                        VStack(alignment: .leading) {
                                            Text("Price Level: \(convertGooglePriceToRange(priceLevel: priceLevel))")
                                        }
                                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineLimit(2)
                                        .padding()
                                        Spacer()
                                    }
                                    Divider()
                                }

                                // MARK: Phone
                                if let phoneNumber = coffeeShop.phoneNumber {
                                    Button(action: {
                                        callCoffeeShop()
                                    }) {
                                        HStack {
                                            Text(phoneNumber.isEmpty ? "Phone number unavailable" : phoneNumber)
                                                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                            Spacer()
                                            Image(systemName: "phone.connection")
                                                .resizable()
                                                .frame(width: geo.size.width * 0.05, height: geo.size.width * 0.05)
                                                .foregroundColor(Color.accentColor)
                                        }
                                    }
                                    .padding()
                                }
                            }
                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                            .background(.bar)
                            .cornerRadius(15)
                            .frame(width: geo.size.width, height: geo.size.height * 0.25)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSafariView) {
                if let url = URL(string: coffeeShop.website ?? "https://nobosoftware.com") {
                    SafariView(url: url)
                }
            }
            .edgesIgnoringSafeArea(.top)
        }
    }

    private func convertGooglePriceToRange(priceLevel: Int) -> String {
        switch priceLevel {
        case 0:
            return "Free"
        case 1:
            return "Inexpensive"
        case 2:
            return "Moderate"
        case 3:
            return "Expensive"
        case 4:
            return "Very Expensive"
        default:
            return "Unknown price range"
        }
    }

    private func buildGooglePhotoURL(photoReference: String?) -> String? {
        guard let photoReference = photoReference else { return nil }
        let apiKey = Secrets.PLACES_API // Replace this with your actual API key management
        return "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=\(photoReference)&key=\(apiKey)"
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
        let phoneNumber = coffeeShop.phoneNumber
        if let url = URL(string: "tel://\(phoneNumber ?? "")"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
