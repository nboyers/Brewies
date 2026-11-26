//
//  ExploreViewModel.swift
//  Brewies
//
//  Owns the Explore tab's search state.
//

import CoreLocation
import Observation

@MainActor
@Observable
final class ExploreViewModel {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var shops: [Shop] = []
    private(set) var phase: Phase = .idle
    private(set) var lastSearchCenter: CLLocationCoordinate2D?

    var category: BrewCategory = .coffee
    var filters = SearchFilters()
    /// Hides shops the user has already logged. Applied by the view, so it doesn't trigger a new search.
    var hideVisited = false

    private var searchTask: Task<Void, Never>?

    /// Runs a search, replacing any search still in flight.
    func search(near center: CLLocationCoordinate2D) {
        searchTask?.cancel()
        phase = .loading
        lastSearchCenter = center

        let category = category
        let filters = filters
        searchTask = Task {
            do {
                let results = try await PlaceSearchService.search(near: center, category: category, filters: filters)
                guard !Task.isCancelled else { return }
                shops = results
                phase = .loaded
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                phase = .failed("Couldn't load shops. Check your connection and try again.")
            }
        }
    }
}
