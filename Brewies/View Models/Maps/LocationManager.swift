//
//  LocationManager.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.

import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var isLocationAccessGranted: Bool = false // Track if location access is granted

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationPermission()
    }
    
    // Request location permission
    func requestLocationPermission() {
        // Only request permission if not already determined
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingLocation()
    }
    
    // CLLocationManagerDelegate method to handle updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            DispatchQueue.main.async {
                self.userLocation = location.coordinate
                
                // Stop updating location after receiving the user's location
                self.locationManager.stopUpdatingLocation()
            }
        }
    }
    
    // Handle permission changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationStatus = status
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationAccessGranted = true
            locationManager.startUpdatingLocation()

        case .denied, .restricted:
            isLocationAccessGranted = false
            locationManager.stopUpdatingLocation()
        default:
            isLocationAccessGranted = false
        }
    }

    
    // Handle failure in getting location
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
        // Optionally stop location updates in case of failure
        locationManager.stopUpdatingLocation()
    }
}
