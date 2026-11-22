//
//  TravelStore.swift
//  Brewies
//
//  Estimates how long it takes to get to a shop, using MapKit routing when available
//  and a distance-based guess until the route arrives.
//

import MapKit
import Observation

enum TravelMode {
    case walking
    case driving

    var verb: String {
        switch self {
        case .walking: return "walk"
        case .driving: return "drive"
        }
    }

    var symbol: String {
        switch self {
        case .walking: return "figure.walk"
        case .driving: return "car.fill"
        }
    }

    var transportType: MKDirectionsTransportType {
        switch self {
        case .walking: return .walking
        case .driving: return .automobile
        }
    }
}

struct TravelInfo {
    let minutes: Int
    let mode: TravelMode
    /// True until a real route has been fetched.
    let isEstimate: Bool
    var route: MKRoute?

    /// For example "6 min walk", or "~6 min walk" for an estimate.
    var label: String {
        "\(isEstimate ? "~" : "")\(minutes) min \(mode.verb)"
    }
}

@MainActor
@Observable
final class TravelStore {
    /// Longest trip that is suggested on foot; anything farther is shown as a drive.
    private static let walkingLimit: TimeInterval = 20 * 60

    private var routes: [String: TravelInfo] = [:]

    /// The best information available right now: a fetched route, or a quick estimate.
    func info(for shop: Shop, from origin: CLLocationCoordinate2D) -> TravelInfo {
        routes[shop.id] ?? Self.estimate(distance: shop.distance(from: origin))
    }

    /// Fetches a real route to the shop. Failures (offline, throttled) leave the estimate in place.
    func load(for shop: Shop, from origin: CLLocationCoordinate2D) async {
        guard routes[shop.id] == nil else { return }
        guard let walking = await fetchRoute(from: origin, to: shop, mode: .walking) else { return }

        if walking.expectedTravelTime <= Self.walkingLimit {
            routes[shop.id] = TravelInfo(minutes: Self.minutes(walking.expectedTravelTime), mode: .walking, isEstimate: false, route: walking)
        } else if let driving = await fetchRoute(from: origin, to: shop, mode: .driving) {
            routes[shop.id] = TravelInfo(minutes: Self.minutes(driving.expectedTravelTime), mode: .driving, isEstimate: false, route: driving)
        } else {
            routes[shop.id] = TravelInfo(minutes: Self.minutes(walking.expectedTravelTime), mode: .walking, isEstimate: false, route: walking)
        }
    }

    // MARK: - Helpers

    private func fetchRoute(from origin: CLLocationCoordinate2D, to shop: Shop, mode: TravelMode) async -> MKRoute? {
        let request = MKDirections.Request()
        request.source = MKMapItem.make(coordinate: origin)
        request.destination = MKMapItem.make(coordinate: shop.coordinate, name: shop.name)
        request.transportType = mode.transportType
        request.requestsAlternateRoutes = false
        return try? await MKDirections(request: request).calculate().routes.first
    }

    private static func minutes(_ seconds: TimeInterval) -> Int {
        max(1, Int((seconds / 60).rounded()))
    }

    /// Straight-line guess: about 3 mph on foot, or about 18 mph in city traffic.
    private static func estimate(distance: CLLocationDistance) -> TravelInfo {
        let walkingSeconds = distance / 1.3
        if walkingSeconds <= walkingLimit {
            return TravelInfo(minutes: minutes(walkingSeconds), mode: .walking, isEstimate: true)
        }
        return TravelInfo(minutes: minutes(distance / 8), mode: .driving, isEstimate: true)
    }
}

private extension MKMapItem {
    /// A map item for a bare coordinate, avoiding the placemark API that newer systems deprecate.
    static func make(coordinate: CLLocationCoordinate2D, name: String? = nil) -> MKMapItem {
        let item: MKMapItem
        if #available(iOS 26, *) {
            item = MKMapItem(location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), address: nil)
        } else {
            item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        }
        item.name = name
        return item
    }
}
