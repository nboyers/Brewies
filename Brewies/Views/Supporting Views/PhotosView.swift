//
//  PhotosView.swift
//  Brewies
//
//  Created by Noah Boyers on 6/10/23.
//

import SwiftUI
import Kingfisher

struct PhotosView: View {
    var photoUrls: [String]
    
    var body: some View {
        ScrollView {
            ForEach(photoUrls, id: \.self) { imageUrl in
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped()
                    .padding()
            }
        }
        .navigationBarTitle("Photos", displayMode: .inline)
    }
}
