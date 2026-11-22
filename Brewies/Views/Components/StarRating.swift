//
//  StarRating.swift
//  Brewies
//

import SwiftUI

/// Read-only stars for a 0...5 rating.
struct StarsView: View {
    let rating: Int
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(index <= rating ? Theme.accent : Color.secondary.opacity(0.4))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rating == 0 ? "Not rated" : "\(rating) out of 5 stars")
    }
}

/// Tappable stars. Tapping the current rating clears it.
struct RatingPicker: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { index in
                Button {
                    rating = rating == index ? 0 : index
                } label: {
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(index <= rating ? Theme.accent : Color.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(index == 1 ? "1 star" : "\(index) stars")
                .accessibilityAddTraits(index == rating ? .isSelected : [])
            }
        }
    }
}
