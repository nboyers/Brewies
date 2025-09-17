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
    @State private var bottomSheetPosition: BottomSheetPosition = .relative(0.0)
    @Environment(\.colorScheme) var colorScheme
    @State private var activeSheet: ActiveSheet?

    @EnvironmentObject var selectedCoffeeShop: SelectedCoffeeShop

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: Header Section
                    VStack(spacing: 16) {
                        if let imageURL = buildGooglePhotoURL(photoReference: coffeeShop.photos?.first) {
                            KFImage(imageURL)
                                .placeholder {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 200)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .font(.largeTitle)
                                                .foregroundColor(.gray)
                                        )
                                }
                                .onFailure { _ in
                                    print("Failed to load header image: \(imageURL)")
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                        Text("No Photo Available")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(coffeeShop.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            if let address = coffeeShop.address {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            HStack(spacing: 12) {
                                RatingView(rating: coffeeShop.rating ?? 0, review_count: String(coffeeShop.userRatingsTotal ?? 0), colorScheme: .primary)
                                
                                if let priceLevel = coffeeShop.priceLevel {
                                    Text(convertGooglePriceToRange(priceLevel: priceLevel))
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))

                    // MARK: Action Buttons
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        Button(action: { openMapsAppWithDirections() }) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Directions")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        if coffeeShop.phoneNumber != nil {
                            Button(action: { callCoffeeShop() }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("Call")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        
                        if coffeeShop.website != nil {
                            Button(action: { showSafariView = true }) {
                                HStack {
                                    Image(systemName: "globe")
                                    Text("Website")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        
                        Button(action: { UIPasteboard.general.string = coffeeShop.address }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy Address")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: Map Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                        
                        SmallMap(coordinate: CLLocationCoordinate2D(latitude: coffeeShop.latitude, longitude: coffeeShop.longitude), name: coffeeShop.name)
                            .frame(height: 200)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)

                                       // MARK: Photos Section
                    if let photos = coffeeShop.photos, !photos.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Photos (\(photos.count))")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(photos.prefix(5), id: \.self) { photoReference in
                                        KFImage(buildGooglePhotoURL(photoReference: photoReference))
                                            .placeholder {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .overlay(
                                                        Image(systemName: "photo")
                                                            .foregroundColor(.gray)
                                                    )
                                            }
                                            .onFailure { error in
                                                print("Photo load failed: \(error.localizedDescription)")
                                            }
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 80)
                                            .clipped()
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 20)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showSafariView) {
            if let url = URL(string: coffeeShop.website ?? "https://nobosoftware.com") {
                SafariView(url: url)
            }
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

    private func buildGooglePhotoURL(photoReference: String?) -> URL? {
        guard let photoReference = photoReference else { return nil }
        let apiKey = Secrets.PLACES_API
        
        // New Google Places API format - use the photo name directly with new endpoint
        if photoReference.hasPrefix("places/") {
            return URL(string: "https://places.googleapis.com/v1/\(photoReference)/media?maxWidthPx=400&key=\(apiKey)")
        } else {
            // Legacy format - use old Photos API
            return URL(string: "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=\(photoReference)&key=\(apiKey)")
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
        let phoneNumber = coffeeShop.phoneNumber
        if let url = URL(string: "tel://\(phoneNumber ?? "")"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
