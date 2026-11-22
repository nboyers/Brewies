//
//  ShopImageStore.swift
//  Brewies
//
//  Loads street-level photos for shops from Look Around, with an in-memory cache.
//

import MapKit
import UIKit

actor ShopImageStore {
    static let shared = ShopImageStore()

    private let cache = NSCache<NSString, UIImage>()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    /// A Look Around snapshot of the shop's street, or nil where Look Around isn't available.
    func image(for shop: Shop) async -> UIImage? {
        let key = shop.id as NSString
        if let cached = cache.object(forKey: key) { return cached }

        if let existing = inFlight[shop.id] {
            return await existing.value
        }

        let latitude = shop.latitude
        let longitude = shop.longitude
        let task = Task { await Self.fetch(latitude: latitude, longitude: longitude) }
        inFlight[shop.id] = task

        let image = await task.value
        inFlight[shop.id] = nil
        if let image { cache.setObject(image, forKey: key) }
        return image
    }

    private static func fetch(latitude: Double, longitude: Double) async -> UIImage? {
        let request = MKLookAroundSceneRequest(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        guard let scene = try? await request.scene else { return nil }

        let options = MKLookAroundSnapshotter.Options()
        options.size = CGSize(width: 640, height: 420)
        let snapshotter = MKLookAroundSnapshotter(scene: scene, options: options)
        return try? await snapshotter.snapshot.image
    }
}
