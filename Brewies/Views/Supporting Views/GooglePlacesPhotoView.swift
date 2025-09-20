//
//  GooglePlacesPhotoView.swift
//  Brewies
//
//  Created by Noah Boyers on 12/19/24.
//

import SwiftUI
import GooglePlaces

struct GooglePlacesPhotoView: UIViewRepresentable {
    let placeID: String
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.systemGray6
        
        // Fetch place details to get photos
        let request = GMSFetchPlaceRequest(placeID: placeID, placeFields: [.photos])
        GMSPlacesClient.shared().fetchPlace(with: request) { place, error in
            if let place = place, let photos = place.photos, !photos.isEmpty {
                let photo = photos[0] // Get first photo
                
                // Load the photo with max width of 400px
                GMSPlacesClient.shared().loadPlacePhoto(photo, constrainedTo: CGSize(width: 400, height: 400), scale: UIScreen.main.scale) { image, error in
                    DispatchQueue.main.async {
                        if let image = image {
                            imageView.image = image
                        } else {
                            // Fallback to default coffee icon
                            imageView.image = UIImage(systemName: "cup.and.saucer.fill")
                            imageView.tintColor = .brown
                        }
                    }
                }
            } else {
                // Fallback to default coffee icon
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