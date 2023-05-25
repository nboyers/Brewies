//
//  LocationManager.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.
// test 12345678
import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocation?
    @Published var location: CLLocation?
    @Published var isLocationAvailable: Bool = false
    @Published var initialRegionSet: Bool = false
    private let locationManager = CLLocationManager()
    
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    
    func requestLocationAccess() {
        locationManager.requestWhenInUseAuthorization()
    }
    

    func getCurrentLocation() -> CLLocationCoordinate2D? {
        return self.userLocation?.coordinate
    }

    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        isLocationAvailable = true
    }
}
