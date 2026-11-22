//
//  PlaceSearchService.swift
//  Brewies
//
//  Finds independent shops around a coordinate using MapKit.
//

import Foundation
import MapKit

struct SearchFilters: Equatable {
    /// About 3 miles or 5 km, matching the options offered in the filters sheet.
    var radiusMeters: Double = Locale.current.measurementSystem == .us ? 4_828 : 5_000
    var independentOnly = true
}

enum PlaceSearchService {
    static func search(
        near center: CLLocationCoordinate2D,
        category: BrewCategory,
        filters: SearchFilters
    ) async throws -> [Shop] {
        let poiFilter = MKPointOfInterestFilter(including: category.mapKitCategories)

        let nearby = MKLocalPointsOfInterestRequest(center: center, radius: filters.radiusMeters)
        nearby.pointOfInterestFilter = poiFilter

        // A text query surfaces shops the category search misses.
        let text = MKLocalSearch.Request()
        text.naturalLanguageQuery = category.searchQuery
        text.region = MKCoordinateRegion(center: center, latitudinalMeters: filters.radiusMeters * 2, longitudinalMeters: filters.radiusMeters * 2)
        text.resultTypes = .pointOfInterest
        text.pointOfInterestFilter = poiFilter

        async let nearbyResult = run(MKLocalSearch(request: nearby))
        async let textResult = run(MKLocalSearch(request: text))
        let results = await [nearbyResult, textResult]

        // Fail only when every request failed; "no results" counts as success.
        if case .failure(let error) = results[0], case .failure = results[1] {
            throw error
        }

        var seen = Set<String>()
        let shops = results
            .flatMap { result -> [MKMapItem] in
                if case .success(let items) = result { return items }
                return []
            }
            .filter { item in
                guard let itemCategory = item.pointOfInterestCategory else { return false }
                return category.mapKitCategories.contains(itemCategory)
            }
            .compactMap { Shop(mapItem: $0, category: category) }
            .filter { seen.insert($0.id).inserted }
            .filter { $0.distance(from: center) <= filters.radiusMeters }
            .filter { !filters.independentOnly || !IndependentShopFilter.isChain($0.name) }

        return shops.sorted { $0.distance(from: center) < $1.distance(from: center) }
    }

    private static func run(_ search: MKLocalSearch) async -> Result<[MKMapItem], Error> {
        do {
            return .success(try await search.start().mapItems)
        } catch let error as MKError where error.code == .placemarkNotFound {
            return .success([])
        } catch {
            return .failure(error)
        }
    }
}
