//
//  RatingView.swift
//  Brewies
//
//  Created by Noah Boyers on 6/12/23.
//

import SwiftUI

import SwiftUI

struct RatingView: View {
    let rating: Double
    let review_count: String
    var colorScheme: Color
    
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
        HStack() {
            Text("\(rating, specifier: "%.1f")")
                .font(.headline)
                .foregroundColor(colorScheme)
            Image("regular_\(imageName)")
            Text("\(review_count) reviews")
                .font(.headline)
                .foregroundColor(colorScheme)
        }
    }
}

#Preview {
    RatingView(rating: 3.5, review_count: "363", colorScheme: .cyan)
}
