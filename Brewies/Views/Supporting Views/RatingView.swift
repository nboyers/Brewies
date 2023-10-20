//
//  RatingView.swift
//  Brewies
//
//  Created by Noah Boyers on 6/12/23.
//

import SwiftUI

struct RatingView: View {
    let rating: Double
    
    var imageName: String {
        let roundedRating = Int(rating)
        let decimalPart = rating - Double(roundedRating)
        if decimalPart == 0.5 {
            return "\(roundedRating)_half"
        } else {
            return "\(roundedRating)"
        }
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Image("regular_\(imageName)")
                .padding(.leading)
            Text("\(rating, specifier: "%.1f")")
                .font(.headline)
                .foregroundColor(.white)
                Image("yelp")
                    .resizable()
                    .aspectRatio(contentMode: .fit)  // Maintain aspect ratio while resizing
                    .frame(width: 50, height: 50)  // Specify the desired width and height
            Spacer()
        }
    }
}
