//
//  ShopCard.swift
//  Brewies
//

import SwiftUI
import MapKit

/// A compact card for the full-screen map's carousel.
struct ShopCard: View {
    let shop: Shop
    var distance: CLLocationDistance?
    var isVisited = false

    var body: some View {
        HStack(spacing: 12) {
            ShopImage(shop: shop)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(shop.name)
                    .font(.display(.headline))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if isVisited {
                    Label("Visited", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .floatingCard()
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        [distance?.formattedDistance, shop.address]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}
