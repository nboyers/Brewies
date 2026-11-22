//
//  DebugSeed.swift
//  Brewies
//
//  Debug builds only: launch with `-seedDemoData` to replace the journal with sample visits,
//  useful for screenshots and for checking streaks.
//

#if DEBUG
import Foundation
import SwiftData

enum DebugSeed {
    @MainActor
    static func seedIfRequested(into context: ModelContext) {
        guard CommandLine.arguments.contains("-seedDemoData") else { return }

        try? context.delete(model: Visit.self)
        try? context.delete(model: SavedShop.self)

        let vault = Shop(id: "demo-vault", name: "The Vault Bookstore", latitude: 45.5231, longitude: -122.6765, category: .coffee, address: "111 SW 5th Ave, Portland")
        let lola = Shop(id: "demo-lola", name: "Lola's Bussdown", latitude: 45.5252, longitude: -122.6755, category: .coffee, address: "28 NW 4th Ave, Portland")
        let kilo = Shop(id: "demo-kilo", name: "Kilo D'Cofi", latitude: 45.5206, longitude: -122.6784, category: .coffee, address: "600 SW Pine St, Portland")
        let fracture = Shop(id: "demo-fracture", name: "Fracture Brewing", latitude: 45.5217, longitude: -122.6787, category: .brewery, address: "431 SW Harvey Milk St, Portland")

        // (shop, weeks ago, rating, order, note). Same weekday each time, so each lands in its own calendar week.
        let entries: [(Shop, Int, Int, String, String)] = [
            (vault, 1, 5, "Flat white", "Quiet table by the window."),
            (vault, 2, 4, "Cortado", ""),
            (vault, 3, 5, "Flat white", "Tried the cardamom bun."),
            (vault, 4, 4, "Flat white", ""),
            (vault, 5, 5, "Pour over", "Ethiopian single origin."),
            (vault, 6, 4, "Cortado", ""),
            (lola, 0, 4, "Cortado", "Great espresso, quiet room."),
            (lola, 1, 5, "Cortado", ""),
            (lola, 2, 4, "Latte", ""),
            (kilo, 0, 3, "Drip coffee", ""),
            (kilo, 4, 4, "Mocha", ""),
            (fracture, 2, 5, "Hazy IPA", "Patio was packed."),
            (fracture, 5, 4, "Pilsner", "")
        ]

        let now = Date()
        for (shop, weeksAgo, rating, order, note) in entries {
            let date = Calendar.current.date(byAdding: .day, value: -7 * weeksAgo, to: now) ?? now
            context.insert(Visit(shop: shop, visitedAt: date, rating: rating, drink: order, notes: note))
        }

        let saved = SavedShop(shop: fracture)
        saved.isFavorite = true
        context.insert(saved)
        try? context.save()
    }
}
#endif
