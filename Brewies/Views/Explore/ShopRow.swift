//
//  ShopRow.swift
//  Brewies
//

import SwiftUI
import MapKit

/// A feed row: street photo, name, how far away it is, and the user's own history with the shop.
struct ShopRow: View {
    let shop: Shop
    var distance: CLLocationDistance?
    var travelLabel: String?
    var myRating: Int?
    var isVisited = false
    var isSaved = false
    var isActive = false

    var body: some View {
        HStack(spacing: 14) {
            ShopImage(shop: shop)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(shop.name)
                    .font(.display(.headline))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let leadLine {
                    Text(leadLine)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.accent)
                        .lineLimit(1)
                }

                if let address = shop.address {
                    Text(address)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if isVisited || isSaved {
                    HStack(spacing: 10) {
                        if isVisited {
                            if let myRating, myRating > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                    StarsView(rating: myRating, size: 10)
                                }
                            } else {
                                Label("Visited", systemImage: "checkmark.circle.fill")
                            }
                        }
                        if isSaved {
                            Image(systemName: "bookmark.fill")
                                .accessibilityLabel("Saved")
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.accent, lineWidth: isActive ? 2 : 0)
        )
        .animation(.snappy(duration: 0.2), value: isActive)
        .contentShape(Rectangle())
    }

    /// "6 min walk · 0.3 mi", falling back to just the distance.
    private var leadLine: String? {
        [travelLabel, distance?.formattedDistance]
            .compactMap { $0 }
            .joined(separator: " · ")
            .nilIfEmpty
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
