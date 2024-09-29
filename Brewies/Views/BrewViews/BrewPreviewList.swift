import SwiftUI
import Kingfisher

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
    
    var isFavorite: Bool { userViewModel.user.favorites.contains(coffeeShop) }
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geo in
                ZStack {
                    // Google Places uses photo references, not URLs. Use a helper function to build the full image URL.
                    if let imageURL = buildGooglePhotoURL(photoReference: coffeeShop.photos?.first) {
                        KFImage(URL(string: imageURL))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width * 0.9, height: geo.size.height * 0.66)
                            .clipped()
                            .cornerRadius(8)
                            .shadow(radius: 4)
                    } else {
                        Text("Image not available")
                            .foregroundColor(.red)
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
        let apiKey = Secrets.PLACES_API // Replace this with your actual API key management
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
