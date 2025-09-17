//
//  SearchResultsView.swift
//  Brewies
//
//  Created by Noah Boyers on 12/19/24.
//

import SwiftUI

struct SearchResultsView: View {
    let locations: [BrewLocation]
    let isCoffeeSelected: Bool
    let onLocationSelected: (BrewLocation) -> Void
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(locations, id: \.id) { location in
                    Button(action: {
                        onLocationSelected(location)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(location.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if let address = location.address, !address.isEmpty {
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                HStack(spacing: 4) {
                                    ForEach(0..<5) { star in
                                        Image(systemName: star < Int(location.rating ?? 0) ? "star.fill" : "star")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    }
                                    Text(String(format: "%.1f", location.rating ?? 0.0))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let userRatingsTotal = location.userRatingsTotal {
                                        Text("(\(userRatingsTotal))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("\(locations.count) \(isCoffeeSelected ? "Coffee Shops" : "Breweries")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onClose()
                    }
                }
            }
        }
    }
}