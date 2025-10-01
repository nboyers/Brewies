//
//  RatingView.swift
//  Brewies
//
//  Created by Noah Boyers on 6/12/23.
//

import SwiftUI

struct RatingView: View {
    let rating: Double
    let review_count: String
    var colorScheme: Color

    var body: some View {
        HStack(spacing: 4) {
            Text("\(rating, specifier: "%.1f")")
                .font(.headline)
                .foregroundColor(colorScheme)
            
            HStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Image(systemName: starType(for: index))
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            
            Text("(\(review_count))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func starType(for index: Int) -> String {
        let starRating = rating - Double(index)
        if starRating >= 1.0 {
            return "star.fill"
        } else if starRating >= 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

#Preview {
    RatingView(rating: 3.5, review_count: "363", colorScheme: .cyan)
}
