import SwiftUI
import Kingfisher
import GooglePlaces

struct GooglePlacesPhotoView: UIViewRepresentable {
    let placeID: String
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.systemGray6
        
        // Fetch place details to get photos
        let request = GMSFetchPlaceRequest(placeID: placeID, placeProperties: ["photos"], sessionToken: nil)
        print("[GooglePlacesPhotoView] Fetching photos for placeID: \(placeID)")
        
        GMSPlacesClient.shared().fetchPlace(with: request) { place, error in
            if let error = error {
                print("[GooglePlacesPhotoView] Fetch place error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    imageView.image = UIImage(systemName: "cup.and.saucer.fill")
                    imageView.tintColor = .brown
                }
                return
            }
            
            if let place = place, let photos = place.photos, !photos.isEmpty {
                let photo = photos[0] // Get first photo
                print("[GooglePlacesPhotoView] Found \(photos.count) photos, loading first one")
                
                // Load the photo with max width of 400px
                GMSPlacesClient.shared().loadPlacePhoto(photo, constrainedTo: CGSize(width: 400, height: 400), scale: UIScreen.main.scale) { image, error in
                    if let error = error {
                        print("[GooglePlacesPhotoView] Load photo error: \(error.localizedDescription)")
                    }
                    
                    DispatchQueue.main.async {
                        if let image = image {
                            print("[GooglePlacesPhotoView] Successfully loaded photo")
                            imageView.image = image
                        } else {
                            print("[GooglePlacesPhotoView] No image returned, using fallback")
                            imageView.image = UIImage(systemName: "cup.and.saucer.fill")
                            imageView.tintColor = .brown
                        }
                    }
                }
            } else {
                print("[GooglePlacesPhotoView] No photos found for place")
                DispatchQueue.main.async {
                    imageView.image = UIImage(systemName: "cup.and.saucer.fill")
                    imageView.tintColor = .brown
                }
            }
        }
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        // No updates needed
    }
}

struct BrewPreviewList: View {
    @Binding var coffeeShops: [BrewLocation]
    @Binding var selectedCoffeeShop: BrewLocation?
    @Binding var showBrewPreview: Bool
    @State private var showAlert = false
    @ObservedObject var storeKit = StoreKitManager()
    @State var showStorefront = false
    @Binding var activeSheet: ActiveSheet?
    @ObservedObject var userViewModel = UserViewModel.shared

    var body: some View {
        ScrollViewReader { scrollView in
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(coffeeShops) { coffeeShop in
                            BrewPreview(coffeeShop: coffeeShop,
                                        activeSheet: $activeSheet,
                                        showBrewPreview: $showBrewPreview)
                            .id(coffeeShop.id)
                        }
                    }
                    .padding([.top, .horizontal])
                }
            }
        }
        .onAppear {
            print("[BrewPreviewList] Showing \(coffeeShops.count) coffee shops")
            for shop in coffeeShops.prefix(3) {
                print("[BrewPreviewList] Shop: \(shop.name), ID: \(shop.id)")
            }
        }
    }
}

struct BrewPreview: View {
    let coffeeShop: BrewLocation
    let BUTTON_WIDTH: CGFloat = 175
    let BUTTON_HEIGHT: CGFloat = 15
    
    @Binding var activeSheet: ActiveSheet?
    @Binding var showBrewPreview: Bool
    @ObservedObject var coffeeShopData = CoffeeShopData.shared
    @ObservedObject var userViewModel = UserViewModel.shared
    @EnvironmentObject var contentVM: ContentViewModel
    @EnvironmentObject var selectedCoffeeShop: SelectedCoffeeShop
    
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme (dark or light mode)
    @EnvironmentObject var sharedAlertVM: SharedAlertViewModel
    
    @State private var isDetailShowing: Bool = false
    @State private var favoriteSlotsUsed = 0
    @State private var showCustomAlertForFavorites = false
    
    @ObservedObject var apiKeysViewModel = APIKeysViewModel.shared
    
    var isFavorite: Bool { userViewModel.user.favorites.contains(coffeeShop) }
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geo in
                ZStack {
                    // Use Google Places SDK photos
                    if !coffeeShop.id.isEmpty {
                        GooglePlacesPhotoView(placeID: coffeeShop.id)
                            .frame(width: geo.size.width * 0.9, height: geo.size.height * 0.66)
                            .clipped()
                            .cornerRadius(8)
                            .shadow(radius: 4)
                            .onAppear {
                                print("[BrewPreview] Creating GooglePlacesPhotoView for \(coffeeShop.name)")
                            }
                    } else {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.brown)
                            .frame(width: geo.size.width * 0.9, height: geo.size.height * 0.66)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .onAppear {
                                print("[BrewPreview] Using fallback image for \(coffeeShop.name) - empty ID")
                            }
                    }
                }
                
                VStack(alignment: .leading) {
                    Spacer().frame(height: geo.size.height / 2)
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(coffeeShop.name)
                                .font(.headline)
                                .foregroundColor(Color.black)
                                .lineLimit(nil)  // Allows text to wrap to the next line
                                .fixedSize(horizontal: false, vertical: true) // Properly wraps text inside a ScrollView
                        }
                        
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
                        Text(coffeeShop.address ?? "Address not available")
                        Text("• \(convertGooglePriceToRange(priceLevel: coffeeShop.priceLevel ?? -1))")
                        Spacer()
                    }

                    .foregroundColor(.gray)
                    .font(.caption)
                    Text(coffeeShop.phoneNumber ?? "Phone number unavailable")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
            }
            .onTapGesture {
                selectBrew()
            }
            .padding()
            
            HStack {
                Spacer()
                RatingView(rating: coffeeShop.rating ?? 0, review_count: String(coffeeShop.userRatingsTotal ?? 0), colorScheme: .black)
                Spacer()
            }
        }
        .frame(width: 300, height: 300)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 4)
    }

    private func selectBrew() {
        selectedCoffeeShop.coffeeShop = coffeeShop
        activeSheet = .detailBrew
    }

    private func toggleFavorite() {
        if isFavorite {
            userViewModel.removeFromFavorites(coffeeShop)
            coffeeShopData.removeFromFavorites(coffeeShop)
            favoriteSlotsUsed -= 1
        } else {
            if coffeeShopData.addToFavorites(coffeeShop) {
                userViewModel.addToFavorites(coffeeShop)
                favoriteSlotsUsed += 1
            } else {
                sharedAlertVM.currentAlertType = .maxFavoritesReached
            }
        }
    }

    private func buildGooglePhotoURL(photoReference: String?) -> String? {
        guard let photoReference = photoReference else { return nil }
        // Try multiple possible property names for the Places API key
        let placesAPIKey = apiKeysViewModel.apiKeys?.placesAPI ?? apiKeysViewModel.apiKeys?.googlePlacesAPIKey
        guard let apiKey = placesAPIKey, !apiKey.isEmpty else { return nil }
        return "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=\(photoReference)&key=\(apiKey)"
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
}

