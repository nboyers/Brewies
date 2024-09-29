//
//  MapView.swift
//  Brewies
//
//  Created by Noah Boyers on 09/29/24.
//
import MapKit
import SwiftUI
import BottomSheet

class BrewLocationAnnotation: MKPointAnnotation {
    var brewLocation: BrewLocation
    
    init(brewLocation: BrewLocation) {
        self.brewLocation = brewLocation
        super.init()
        self.title = brewLocation.name
        self.coordinate = CLLocationCoordinate2D(latitude: brewLocation.latitude, longitude: brewLocation.longitude)
    }
}

struct MapView: UIViewRepresentable {
    var locationManager: LocationManager
    @EnvironmentObject var sharedVM: SharedViewModel
    
    // Bindings to hold brew location data
    @Binding var coffeeShops: [BrewLocation]
    @Binding var selectedCoffeeShop: BrewLocation?
    @Binding var centeredOnUser: Bool
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
    var brewLocationAnnotationMap = [UUID: BrewLocationAnnotation]()
    
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
        mapView.addGestureRecognizer(tapRecognizer)
        
        DispatchQueue.main.async {
            self.setRegion = { region in
                mapView.setRegion(region, animated: true)
            }
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
        
        // Center map on user if permission is granted and centeredOnUser is true
        
        if locationManager.isLocationAccessGranted && centeredOnUser {
            setRegion(to: userLocation, on: mapView) // Set the region to user location
            centeredOnUser = false // Reset after centering
            showUserLocationButton = false
        }
        
        // Handle searched location or other updates...
        if let searchedLocation = searchedLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = searchedLocation
            annotation.title = searchQuery
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                mapView.addAnnotation(annotation)
                self.setRegion?(MKCoordinateRegion(center: searchedLocation, latitudinalMeters: DISTANCE, longitudinalMeters: DISTANCE)) // Update region
                self.searchedLocation = nil // Reset for new searches
            }
        }
        
        
        // Update annotations
        updateAnnotations(for: mapView)
        
        // Select annotation if a coffee shop is already selected
        if let selectedCoffeeShop = selectedCoffeeShop {
            selectCoffeeShopAnnotation(in: mapView, for: selectedCoffeeShop)
        }
    }
    
    private func addSearchedLocationAnnotation(to mapView: MKMapView) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = searchedLocation!
        annotation.title = searchQuery
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            mapView.addAnnotation(annotation)
            self.setRegion?(MKCoordinateRegion(center: searchedLocation!, latitudinalMeters: DISTANCE, longitudinalMeters: DISTANCE))
            self.searchedLocation = nil
        }
    }
    
    // Updates the annotations on the MKMapView based on the coffeeShops data
    private func updateAnnotations(for mapView: MKMapView) {
        let existingAnnotations = mapView.annotations.compactMap { $0 as? BrewLocationAnnotation }
        
        // Get the existing annotation IDs
        let existingIDs = Set(existingAnnotations.map { $0.brewLocation.id })
        let coffeeShopsMap = Dictionary(uniqueKeysWithValues: coffeeShops.map { ($0.id, $0) })
        
        // Remove outdated annotations
        for annotation in existingAnnotations where !coffeeShopsMap.keys.contains(annotation.brewLocation.id) {
            mapView.removeAnnotation(annotation)
        }
        
        // Add missing annotations
        let missingShops = coffeeShops.filter { !existingIDs.contains($0.id) }
        addAnnotationsInBatches(for: missingShops, to: mapView)
    }
    
    private func addAnnotationsInBatches(for brewLocations: [BrewLocation], to mapView: MKMapView) {
        let batchSize = 50
        let batches = stride(from: 0, to: brewLocations.count, by: batchSize).map {
            Array(brewLocations[$0..<min($0 + batchSize, brewLocations.count)])
        }
        
        for batch in batches {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                for brewLocation in batch {
                    let annotation = BrewLocationAnnotation(brewLocation: brewLocation)
                    mapView.addAnnotation(annotation)
                }
            }
        }
    }
    
    private func selectCoffeeShopAnnotation(in mapView: MKMapView, for coffeeShop: BrewLocation) {
        if let annotation = mapView.annotations.first(where: {
            $0.coordinate.latitude == coffeeShop.latitude && $0.coordinate.longitude == coffeeShop.longitude
        }) as? MKPointAnnotation {
            mapView.selectAnnotation(annotation, animated: true)
        }
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
            
            // Create CLLocation instances for the user's location and the center of the map
            if let userLocation = parent.locationManager.userLocation {
                let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                let centerCLLocation = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
                
                // Calculate the distance between the user's location and the center of the map
                let distanceFromUser = centerCLLocation.distance(from: userCLLocation)
                
                // Update the state based on the distance
                parent.userHasMoved = distanceFromUser > parent.DISTANCE / 2
                parent.showUserLocationButton = parent.userHasMoved
                parent.shouldSearchInArea = true // Signal search in this area
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let brewLocation = parent.coffeeShops.first(where: {
                $0.latitude == view.annotation?.coordinate.latitude && $0.longitude == view.annotation?.coordinate.longitude
            }) {
                parent.selectedCoffeeShop = brewLocation
                parent.showBrewPreview = true
                
                if let index = parent.coffeeShops.firstIndex(of: brewLocation) {
                    parent.coffeeShops.remove(at: index)
                    parent.coffeeShops.insert(brewLocation, at: 0)
                }
                
                DispatchQueue.main.async {
                    self.updateBottomSheetPosition.wrappedValue = .relative(0.70)
                }
            }
        }
    }
}
