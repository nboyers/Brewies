import SwiftUI

struct BrewListItem: View {
    let location: BrewLocation
    let photoIndex: Int
    @Binding var activeSheet: ActiveSheet?
    @ObservedObject var userViewModel = UserViewModel.shared
    
    init(location: BrewLocation, photoIndex: Int = 0, activeSheet: Binding<ActiveSheet?>) {
        self.location = location
        self.photoIndex = photoIndex
        self._activeSheet = activeSheet
    }
    
    private var isFavorite: Bool {
        userViewModel.user.favorites.contains(location)
    }
    
    private var canAddFavorite: Bool {
        userViewModel.canAddFavorite()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Photo
            GooglePlacesPhotoView(placeID: location.id, photoIndex: photoIndex)
                .id("\(location.id)-\(photoIndex)")
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(UIColor.separator), lineWidth: 0.5)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(location.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: toggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isFavorite ? .red : (userViewModel.canAddFavorite() ? .secondary : .gray.opacity(0.5)))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isFavorite && !userViewModel.canAddFavorite())
                }
                
                if let rating = location.rating {
                    HStack(spacing: 4) {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(rating.rounded()) ? "star.fill" : "star")
                                    .font(.system(size: 12))
                                    .foregroundColor(index < Int(rating.rounded()) ? .yellow : .secondary)
                            }
                        }
                        
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if let reviewCount = location.userRatingsTotal, reviewCount > 0 {
                            Text("(\(reviewCount))")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let priceLevel = location.priceLevel, priceLevel >= 0 {
                            Text(priceText(for: priceLevel))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let address = location.address {
                    Text(address)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(UIColor.separator))
                .offset(y: 0),
            alignment: .bottom
        )
    }
    
    private func toggleFavorite() {
        if isFavorite {
            userViewModel.removeFromFavorites(location)
        } else if userViewModel.canAddFavorite() {
            userViewModel.addToFavorites(location)
        } else {
            // Show upgrade prompt when at limit
            activeSheet = .storefront
        }
    }
    
    private func priceText(for priceLevel: Int) -> String {
        switch priceLevel {
        case 0: return "Free"
        case 1: return "$"
        case 2: return "$$"
        case 3: return "$$$"
        case 4: return "$$$$"
        default: return ""
        }
    }
}

