//
//  Shop.swift
//  Brewies
//
//  A place found through MapKit search, or rebuilt from the user's own saved data.
//

import Foundation
import MapKit

enum BrewCategory: String, CaseIterable, Identifiable {
    case coffee
    case brewery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .coffee: return "Coffee"
        case .brewery: return "Breweries"
        }
    }

    /// Singular noun for a place in this category.
    var placeName: String {
        switch self {
        case .coffee: return "Coffee shop"
        case .brewery: return "Brewery"
        }
    }

    var searchQuery: String {
        switch self {
        case .coffee: return "coffee shop"
        case .brewery: return "brewery"
        }
    }

    var mapKitCategories: [MKPointOfInterestCategory] {
        switch self {
        case .coffee: return [.cafe]
        case .brewery: return [.brewery, .distillery, .winery]
        }
    }
}

struct Shop: Identifiable, Hashable {
    /// MapKit's persistent place identifier, or a name-and-position fallback.
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    var category: BrewCategory = .coffee
    var address: String?
    var phoneNumber: String?
    var website: URL?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func distance(from other: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }

    /// A Maps link that opens turn-by-turn directions to the shop.
    var directionsURL: URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "daddr", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "q", value: name)
        ]
        return components?.url
    }

    /// A Maps link that shows the shop's pin, suitable for sending to a friend.
    var shareURL: URL {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "ll", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "q", value: name)
        ]
        return components?.url ?? URL(string: "https://maps.apple.com/")!
    }

    var shareMessage: String {
        guard let address, !address.isEmpty else { return "Let's go to \(name)." }
        return "Let's go to \(name), \(address)."
    }

    var phoneURL: URL? {
        guard let phoneNumber else { return nil }
        let digits = phoneNumber.filter { $0.isNumber || $0 == "+" }
        return digits.isEmpty ? nil : URL(string: "tel:\(digits)")
    }
}

// MARK: - Construction

extension Shop {
    init?(mapItem: MKMapItem, category: BrewCategory) {
        guard let name = mapItem.name, !name.isEmpty else { return nil }
        let coordinate = mapItem.shopCoordinate
        guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }

        let fallbackID = "\(name)@\(String(format: "%.5f,%.5f", coordinate.latitude, coordinate.longitude))"
        self.init(
            id: mapItem.identifier?.rawValue ?? fallbackID,
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            category: category,
            address: mapItem.shopAddress,
            phoneNumber: mapItem.phoneNumber,
            website: mapItem.url
        )
    }

    init(visit: Visit) {
        self.init(
            id: visit.shopID,
            name: visit.shopName,
            latitude: visit.latitude,
            longitude: visit.longitude,
            category: BrewCategory(rawValue: visit.categoryRaw) ?? .coffee,
            address: visit.address.isEmpty ? nil : visit.address
        )
    }

    init(saved: SavedShop) {
        self.init(
            id: saved.shopID,
            name: saved.name,
            latitude: saved.latitude,
            longitude: saved.longitude,
            category: BrewCategory(rawValue: saved.categoryRaw) ?? .coffee,
            address: saved.address.isEmpty ? nil : saved.address
        )
    }
}

private extension MKMapItem {
    var shopCoordinate: CLLocationCoordinate2D {
        if #available(iOS 26, *) {
            return location.coordinate
        } else {
            return placemark.coordinate
        }
    }

    var shopAddress: String? {
        if #available(iOS 26, *) {
            return address?.shortAddress ?? address?.fullAddress
        } else {
            let street = [placemark.subThoroughfare, placemark.thoroughfare]
                .compactMap { $0 }
                .joined(separator: " ")
            let parts = [street, placemark.locality ?? ""].filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }
    }
}

// MARK: - Framing

extension MKCoordinateRegion {
    /// A region that frames the shops so pins spread out instead of piling up at a fixed zoom.
    /// Falls back to a square of `fallbackMeters` around `center` when there is nothing to frame.
    static func framing(
        _ shops: [Shop],
        center: CLLocationCoordinate2D,
        fallbackMeters: Double,
        padding: Double = 1.5
    ) -> MKCoordinateRegion {
        guard shops.count > 1 else {
            return MKCoordinateRegion(center: center, latitudinalMeters: fallbackMeters, longitudinalMeters: fallbackMeters)
        }
        return framing(coordinates: shops.map(\.coordinate), padding: padding)
    }

    /// A region that frames every coordinate, with a minimum span so a close pair doesn't zoom to street level.
    static func framing(
        coordinates: [CLLocationCoordinate2D],
        padding: Double = 1.5,
        minimumSpan: Double = 0.008
    ) -> MKCoordinateRegion {
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * padding, minimumSpan),
                longitudeDelta: max((maxLon - minLon) * padding, minimumSpan)
            )
        )
    }
}

// MARK: - Display

extension CLLocationDistance {
    /// Distance formatted for the user's locale, e.g. "300 ft", "0.4 mi", "650 m" or "2.1 km".
    var formattedDistance: String {
        if Locale.current.measurementSystem == .us {
            let feet = self * 3.28084
            if feet < 528 { return "\(Int((feet / 10).rounded()) * 10) ft" }
            return String(format: "%.1f mi", self / 1609.344)
        }
        if self < 1_000 { return "\(Int((self / 10).rounded()) * 10) m" }
        return String(format: "%.1f km", self / 1_000)
    }
}
