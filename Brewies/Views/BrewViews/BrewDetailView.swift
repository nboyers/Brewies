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
import GooglePlaces

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct BrewDetailView: View {
    var coffeeShop: BrewLocation

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showSafariView = false
    @State private var showHoursSheet = false
    @State private var bottomSheetPosition: BottomSheetPosition = .relative(0.0)
    @Environment(\.colorScheme) var colorScheme
    @State private var activeSheet: ActiveSheet?
    @State private var placePhoto: UIImage? = nil
    @State private var isLoadingPlacePhoto = false
    @State private var heroImage: UIImage? = nil
    @State private var isLoadingHeroImage = false

    @EnvironmentObject var selectedCoffeeShop: SelectedCoffeeShop

    @ObservedObject var apiKeysViewModel = APIKeysViewModel.shared

    // Safely resolve the Google Places API key
    private var placesAPIKey: String? {
        guard let keys = apiKeysViewModel.apiKeys else { return nil }
        
        // Access properties directly to avoid key-value coding issues
        if !keys.PLACES_API.isEmpty {
            return keys.PLACES_API
        }
        
        if let placesAPI = keys.placesAPI, !placesAPI.isEmpty {
            return placesAPI
        }
        
        if let googlePlacesAPIKey = keys.googlePlacesAPIKey, !googlePlacesAPIKey.isEmpty {
            return googlePlacesAPIKey
        }
        
        return nil
    }
    
    private func loadFirstPlacePhoto(placeID: String) {
        guard !isLoadingPlacePhoto else { return }
        isLoadingPlacePhoto = true

        let client = GMSPlacesClient.shared()
        client.lookUpPhotos(forPlaceID: placeID) { photoMetadataList, error in
            if let error = error {
                print("[BrewDetailView] lookUpPhotos error:", error.localizedDescription)
                self.isLoadingPlacePhoto = false
                return
            }

            guard let first = photoMetadataList?.results.first else {
                print("[BrewDetailView] No photo metadata for place")
                self.isLoadingPlacePhoto = false
                return
            }

            client.loadPlacePhoto(first) { image, error in
                if let error = error {
                    print("[BrewDetailView] loadPlacePhoto error:", error.localizedDescription)
                }
                self.placePhoto = image
                self.isLoadingPlacePhoto = false
            }
        }
    }
    
    private func loadHeroImage(photoRef: String, apiKey: String) {
        guard !isLoadingHeroImage else { return }
        isLoadingHeroImage = true
        
        let urlString: String
        if photoRef.hasPrefix("places/") {
            urlString = "https://places.googleapis.com/v1/\(photoRef)/media?maxWidthPx=800"
        } else {
            urlString = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=\(photoRef)&key=\(apiKey)"
        }
        
        print("[BrewDetailView] Loading hero image from URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("[BrewDetailView] Invalid URL: \(urlString)")
            isLoadingHeroImage = false
            return
        }
        
        var request = URLRequest(url: url)
        if photoRef.hasPrefix("places/") {
            request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
            print("[BrewDetailView] Using v1 API with X-Goog-Api-Key header")
        } else {
            print("[BrewDetailView] Using legacy API with key in URL")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[BrewDetailView] Image load error: \(error.localizedDescription)")
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[BrewDetailView] Image response status: \(httpResponse.statusCode)")
            }
            
            DispatchQueue.main.async {
                self.isLoadingHeroImage = false
                if let data = data, let image = UIImage(data: data) {
                    print("[BrewDetailView] Successfully loaded hero image")
                    self.heroImage = image
                } else {
                    print("[BrewDetailView] Failed to create image from data")
                }
            }
        }.resume()
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    Group {}.onAppear {
                        let hasKey = (placesAPIKey?.isEmpty == false)
                        let firstRef = coffeeShop.photos?.first ?? "<nil>"
                        print("[BrewDetailView] has Places key:", hasKey, "first photo ref:", firstRef)
                        let placeID = coffeeShop.id
                        if !placeID.isEmpty {
                            print("[BrewDetailView] Loading SDK photo for placeID:", placeID)
                            loadFirstPlacePhoto(placeID: placeID)
                        } else {
                            print("[BrewDetailView] No placeID available to load SDK photo")
                        }
                        
                        // Load hero image from photo reference
                        if let apiKey = placesAPIKey, !apiKey.isEmpty,
                           let photoRef = coffeeShop.photos?.first {
                            loadHeroImage(photoRef: photoRef, apiKey: apiKey)
                        }
                    }
                    
                    // MARK: Hero Image
                    ZStack(alignment: .bottomLeading) {
                        if let uiImage = placePhoto {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 280)
                                .clipped()
                        } else if let heroImage = heroImage {
                            Image(uiImage: heroImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 280)
                                .clipped()
                        } else if isLoadingHeroImage {
                            Rectangle()
                                .fill(LinearGradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                                .frame(height: 280)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                )
                        } else {
                            Rectangle()
                                .fill(LinearGradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                                .frame(height: 280)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "building.2")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray.opacity(0.6))
                                        Text("No Image Available")
                                            .font(.caption)
                                            .foregroundColor(.gray.opacity(0.8))
                                    }
                                )
                        }
                        
                        LinearGradient(colors: [Color.black.opacity(0.6), Color.clear], startPoint: .bottom, endPoint: .top)
                            .frame(height: 120)
                    }
                    
                    // MARK: Content Card
                    VStack(spacing: 24) {
                        // Business Info
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(coffeeShop.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                if let address = coffeeShop.address {
                                    HStack(spacing: 6) {
                                        Image(systemName: "location")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(address)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                            }
                            
                            HStack(spacing: 16) {
                                RatingView(rating: coffeeShop.rating ?? 0, review_count: String(coffeeShop.userRatingsTotal ?? 0), colorScheme: .primary)
                                
                                if let priceLevel = coffeeShop.priceLevel {
                                    Text(convertGooglePriceToRange(priceLevel: priceLevel))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Action Buttons
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            Button(action: { openMapsAppWithDirections() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Directions")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            
                            if coffeeShop.phoneNumber != nil {
                                Button(action: { callCoffeeShop() }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Call")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                            }
                            
                            if coffeeShop.website != nil {
                                Button(action: { showSafariView = true }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "globe")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Website")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                            }
                            
                            Button(action: { UIPasteboard.general.string = coffeeShop.address }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Copy Address")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }
                        
                        Divider()
                        
                        // Map Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "map")
                                    .foregroundColor(.blue)
                                Text("Location")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            
                            SmallMap(coordinate: CLLocationCoordinate2D(latitude: coffeeShop.latitude, longitude: coffeeShop.longitude), name: coffeeShop.name)
                                .frame(height: 200)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                        
                        // Photos Section
                        if let photos = coffeeShop.photos, !photos.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                        .foregroundColor(.blue)
                                    Text("Photos")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Text("(\(photos.count))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        if let apiKey = placesAPIKey, !apiKey.isEmpty {
                                            ForEach(photos.prefix(8), id: \.self) { photoReference in
                                                GooglePlacesImageView(
                                                    photoReference: photoReference,
                                                    apiKey: apiKey,
                                                    width: 140,
                                                    height: 100
                                                )
                                                .clipped()
                                                .cornerRadius(12)
                                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 2)
                                }
                            }
                        }
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                    .offset(y: -20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
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
        guard let apiKey = placesAPIKey, !apiKey.isEmpty else {
            print("[BrewDetailView] No Places API key available when building photo URL")
            return nil
        }
        guard let photoReference = photoReference else {
            print("[BrewDetailView] No photo reference provided")
            return nil
        }

        if photoReference.hasPrefix("places/") {
            let urlString = "https://places.googleapis.com/v1/\(photoReference)/media?maxWidthPx=400&key=\(apiKey)"
            print("[BrewDetailView] Using v1 photo URL:", urlString)
            return URL(string: urlString)
        } else {
            let urlString = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=\(photoReference)&key=\(apiKey)"
            print("[BrewDetailView] Using legacy photo URL:", urlString)
            return URL(string: urlString)
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
