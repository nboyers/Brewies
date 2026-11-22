//
//  ShopImage.swift
//  Brewies
//

import SwiftUI

/// A shop photo from Look Around, falling back to branded artwork where none exists.
struct ShopImage: View {
    let shop: Shop

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.accent.opacity(0.32), Theme.accent.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else {
                CategoryIcon(category: shop.category, size: 34)
                    .foregroundStyle(Theme.accent.opacity(0.45))
            }
        }
        .clipped()
        .animation(.easeOut(duration: 0.25), value: image != nil)
        .task(id: shop.id) {
            image = await ShopImageStore.shared.image(for: shop)
        }
        .accessibilityHidden(true)
    }
}
