//
//  LocationService.swift
//  Brewies
//
//  Provides the user's location once, and reports when access is denied.
//

import CoreLocation
import Observation

@MainActor
@Observable
final class LocationService {
    private(set) var coordinate: CLLocationCoordinate2D?
    private(set) var isDenied = false

    private var session: CLServiceSession?
    private var updatesTask: Task<Void, Never>?

    /// Requests access if needed and waits for a first location fix.
    func start() {
        guard updatesTask == nil else { return }
        session = CLServiceSession(authorization: .whenInUse)

        updatesTask = Task {
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    isDenied = update.authorizationDenied || update.authorizationDeniedGlobally
                    if let location = update.location {
                        coordinate = location.coordinate
                        break
                    }
                }
            } catch {
                // Location updates ended; the UI falls back to the manual search prompt.
            }
            session?.invalidate()
            session = nil
            updatesTask = nil
        }
    }
}
