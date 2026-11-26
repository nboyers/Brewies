//
//  VisitRow.swift
//  Brewies
//

import SwiftUI

/// A compact visit summary used inside a shop's detail screen.
struct VisitRow: View {
    let visit: Visit

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    StarsView(rating: visit.rating)
                    Text(visit.visitedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !visit.drink.isEmpty {
                    Text(visit.drink)
                        .font(.subheadline.weight(.medium))
                }

                if !visit.notes.isEmpty {
                    Text(visit.notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer(minLength: 0)

            if let data = visit.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// A journal entry card used in the Passport.
struct VisitCard: View {
    let visit: Visit

    private var category: BrewCategory {
        BrewCategory(rawValue: visit.categoryRaw) ?? .coffee
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let data = visit.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 170)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(visit.shopName)
                        .font(.display(.headline))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    Text(visit.visitedAt.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                StarsView(rating: visit.rating, size: 13)

                if !visit.drink.isEmpty {
                    HStack(spacing: 6) {
                        CategoryIcon(category: category, size: 13)
                        Text(visit.drink)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(Theme.accent)
                }

                if !visit.notes.isEmpty {
                    Text(visit.notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .card()
        .contentShape(Rectangle())
    }
}
