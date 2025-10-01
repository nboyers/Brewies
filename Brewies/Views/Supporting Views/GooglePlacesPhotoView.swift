import SwiftUI
import UIKit

struct GooglePlacesPhotoView: UIViewRepresentable {
    let placeID: String
    let photoIndex: Int
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var hasFailed = false
    
    private var uniqueKey: String {
        "\(placeID)-\(photoIndex)"
    }
    
    init(placeID: String, photoIndex: Int = 0) {
        self.placeID = placeID
        self.photoIndex = photoIndex
    }
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.systemGray5
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        // Set a unique tag to identify this specific photo instance
        uiView.tag = uniqueKey.hashValue
        uiView.image = nil
        
        if let loadedImage = loadedImage {
            uiView.image = loadedImage
            return
        }
        
        if hasFailed {
            uiView.image = UIImage(systemName: "photo")
            return
        }
        
        if !isLoading {
            uiView.image = UIImage(systemName: "photo.circle")
            Task {
                await fetchPlacePhoto(for: placeID, imageView: uiView)
            }
        }
    }
    
    private func fetchPlacePhoto(for placeID: String, imageView: UIImageView) async {
        await MainActor.run {
            isLoading = true
        }
        
        guard let apiKey = Bundle.main.infoDictionary?["GOOGLE_PLACES_API"] as? String else {
            print("[GooglePlacesPhotoView] API key not found")
            await MainActor.run {
                isLoading = false
                hasFailed = true
                guard imageView.tag == uniqueKey.hashValue else { return }
                imageView.image = UIImage(systemName: "photo")
            }
            return
        }
        
        // Use Places API (New) to get place details with photos
        let url = URL(string: "https://places.googleapis.com/v1/places/\(placeID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("photos", forHTTPHeaderField: "X-Goog-FieldMask")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[GooglePlacesPhotoView] API Response Status: \(httpResponse.statusCode)")
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("[GooglePlacesPhotoView] API Response: \(responseString)")
            }
            
            let placeResponse = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)
            
            guard let photos = placeResponse.photos, !photos.isEmpty else {
                print("[GooglePlacesPhotoView] No photos available for place ID: \(placeID)")
                await MainActor.run {
                    isLoading = false
                    hasFailed = true
                    guard imageView.tag == uniqueKey.hashValue else { return }
                    imageView.image = UIImage(systemName: "photo")
                }
                return
            }
            
            // Use modulo to cycle through available photos
            let actualIndex = photoIndex % photos.count
            let selectedPhoto = photos[actualIndex]
            
            // Fetch the actual photo
            let photoURL = "https://places.googleapis.com/v1/\(selectedPhoto.name)/media?maxWidthPx=400&key=\(apiKey)"
            guard let photoURLObj = URL(string: photoURL) else { return }
            
            let (imageData, _) = try await URLSession.shared.data(from: photoURLObj)
            
            if let image = UIImage(data: imageData) {
                await MainActor.run {
                    isLoading = false
                    loadedImage = image
                    guard imageView.tag == uniqueKey.hashValue else { return }
                    imageView.image = image
                }
            } else {
                await MainActor.run {
                    isLoading = false
                    hasFailed = true
                    guard imageView.tag == uniqueKey.hashValue else { return }
                    imageView.image = UIImage(systemName: "photo")
                }
            }
            
        } catch {
            print("[GooglePlacesPhotoView] Error fetching photo for \(placeID): \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
                hasFailed = true
                guard imageView.tag == uniqueKey.hashValue else { return }
                imageView.image = UIImage(systemName: "photo")
            }
        }
    }
}

struct PlaceDetailsResponse: Codable {
    let photos: [PlacePhoto]?
}

struct PlacePhoto: Codable {
    let name: String
}
