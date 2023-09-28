//
//  MapView.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.
//

//
//  MapView.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.
//
import MapKit
import SwiftUI
import BottomSheet

struct MapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @EnvironmentObject var sharedVM: SharedViewModel
    
    // Bindings
    @Binding var coffeeShops: [CoffeeShop]
    @Binding var selectedCoffeeShop: CoffeeShop?
    @Binding var centeredOnUser: Bool
    @Binding var mapView: MKMapView
    @Binding var userHasMoved: Bool
    @Binding var visibleRegionCenter: CLLocationCoordinate2D?
    @Binding var showUserLocationButton: Bool
    @State var setRegion: ((MKCoordinateRegion) -> Void)?
    @Binding var isAnnotationSelected: Bool
    @Binding var mapTapped: Bool
    @Binding var showBrewPreview: Bool
    @Binding var searchedLocation: CLLocationCoordinate2D?
    @Binding var searchQuery: String
    @Binding var shouldSearchInArea: Bool


    let DISTANCE = CLLocationDistance(2500)
    
    // Creates the coordinator for the MapView
    func makeCoordinator() -> Coordinator {
        return Coordinator(self, sharedVM: sharedVM, updateBottomSheetPosition: $sharedVM.bottomSheetPosition)
    }


    
    // Creates and configures the MKMapView
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.mapTapped))
        tapRecognizer.delegate = context.coordinator as? UIGestureRecognizerDelegate
        mapView.addGestureRecognizer(tapRecognizer)
        
        
        DispatchQueue.main.async {
            self.setRegion = { region in
                mapView.setRegion(region, animated: true)
            }
            self.mapView = mapView
        }
        
        return mapView
    }
    
    // Sets the region of the MKMapView to the specified coordinate
    func setRegion(to coordinate: CLLocationCoordinate2D, on mapView: MKMapView) {
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: DISTANCE, longitudinalMeters: DISTANCE)
        mapView.setRegion(region, animated: true)
    }
    
    // Updates the MKMapView with the latest data
    func updateUIView(_ mapView: MKMapView, context: Context) {
        guard let userLocation = locationManager.userLocation else { return }
        
        // Set initial region if it hasn't been set before
        if !locationManager.initialRegionSet {
            setRegion(to: userLocation.coordinate, on: mapView)
            DispatchQueue.main.async {
                self.locationManager.initialRegionSet = true
            }
        }
        // Update for searched location
        if let searchedLocation = searchedLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = searchedLocation
            annotation.title = searchQuery
            DispatchQueue.main.async {
                mapView.addAnnotation(annotation)
                self.setRegion?(MKCoordinateRegion(center: searchedLocation, latitudinalMeters: DISTANCE, longitudinalMeters: DISTANCE)) // Update here
                self.searchedLocation = nil // Reset to allow for new searches
            }
        }
        
        
        
        
        // Center map on user if requested
        if centeredOnUser {
            setRegion(to: userLocation.coordinate, on: mapView)
            centeredOnUser = false
            showUserLocationButton = false
        }
        
        // Update annotations
        updateAnnotations(for: mapView)
        
        // Select annotation if a coffee shop is already selected
        if let selectedCoffeeShop = selectedCoffeeShop,
           let annotation = mapView.annotations.first(where: { $0.coordinate.latitude == selectedCoffeeShop.latitude && $0.coordinate.longitude == selectedCoffeeShop.longitude }) as? MKPointAnnotation {
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    // Updates the annotations on the MKMapView based on the coffeeShops data
    private func updateAnnotations(for mapView: MKMapView) {
        let existingAnnotations = Set(mapView.annotations.compactMap { $0 as? MKPointAnnotation })
        let newAnnotations = Set(coffeeShops.map(coffeeShopToAnnotation))
        
        // Remove annotations not in the new set
        let annotationsToRemove = existingAnnotations.subtracting(newAnnotations)
        DispatchQueue.main.async {
            mapView.removeAnnotations(Array(annotationsToRemove))
        }
        
        // Add annotations not in the existing set
        let annotationsToAdd = newAnnotations.subtracting(existingAnnotations)
        DispatchQueue.main.async {
            mapView.addAnnotations(Array(annotationsToAdd))
        }
    }
    
    // Converts a CoffeeShop object to an MKPointAnnotation
    private func coffeeShopToAnnotation(_ coffeeShop: CoffeeShop) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: coffeeShop.latitude, longitude: coffeeShop.longitude)
        annotation.title = coffeeShop.name
        return annotation
    }
    
    // Sets the initial region of the MKMapView based on the user's location
    func setInitialRegion(for mapView: MKMapView) {
        guard let userLocation = locationManager.userLocation else { return }
        let region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: DISTANCE, longitudinalMeters: DISTANCE)
        mapView.setRegion(region, animated: false)
    }
    
    // Coordinator class that handles delegate callbacks and actions
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var sharedVM: SharedViewModel
        var updateBottomSheetPosition: Binding<BottomSheetPosition>


        init(_ parent: MapView, sharedVM: SharedViewModel, updateBottomSheetPosition: Binding<BottomSheetPosition>) {
            self.parent = parent
            self.sharedVM = sharedVM
            self.updateBottomSheetPosition = updateBottomSheetPosition
        }

        @objc func mapTapped() {
            parent.mapTapped = true
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.visibleRegionCenter = mapView.centerCoordinate
            let userLocation = parent.locationManager.userLocation?.coordinate
            let distanceFromUser = mapView.centerCoordinate.distance(from: userLocation)
            parent.userHasMoved = distanceFromUser > parent.DISTANCE / 2
            parent.showUserLocationButton = parent.userHasMoved
            // Signal that the user has moved the map and might want to search in this area
            parent.shouldSearchInArea = true
        }
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
          if let coffeeShop = parent.coffeeShops.first(where: { $0.latitude == view.annotation?.coordinate.latitude && $0.longitude == view.annotation?.coordinate.longitude }) {
                parent.selectedCoffeeShop = coffeeShop
                parent.showBrewPreview = true

                // Move the selected coffee shop to the front of the array
                if let index = parent.coffeeShops.firstIndex(of: coffeeShop) {
                    parent.coffeeShops.remove(at: index)
                    parent.coffeeShops.insert(coffeeShop, at: 0)
                }

                // Change the bottomSheetPosition to make it appear
                DispatchQueue.main.async {
                    self.updateBottomSheetPosition.wrappedValue = .relative(0.70)
                }
            }
        }
    }
}

// Extension on CLLocationCoordinate2D to calculate the distance between coordinates
extension CLLocationCoordinate2D {
    func distance(from coordinate: CLLocationCoordinate2D?) -> CLLocationDistance {
        guard let coordinate = coordinate else { return .greatestFiniteMagnitude }
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }
}
