import SwiftUI
import Foundation

struct GooglePlacesImageView: View {
    let photoReference: String
    let apiKey: String
    let width: CGFloat
    let height: CGFloat
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
        .frame(width: width, height: height)
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard !apiKey.isEmpty else {
            isLoading = false
            return
        }
        
        let urlString: String
        if photoReference.hasPrefix("places/") {
            urlString = "https://places.googleapis.com/v1/\(photoReference)/media?maxWidthPx=\(Int(width * 2))"
        } else {
            urlString = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=\(Int(width * 2))&photoreference=\(photoReference)&key=\(apiKey)"
            loadLegacyImage(urlString: urlString)
            return
        }
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let data = data, let uiImage = UIImage(data: data) {
                    image = uiImage
                }
            }
        }.resume()
    }
    
    private func loadLegacyImage(urlString: String) {
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let data = data, let uiImage = UIImage(data: data) {
                    image = uiImage
                }
            }
        }.resume()
    }
}