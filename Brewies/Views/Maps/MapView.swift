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
import SwiftUI
import MapKit
import Combine

struct MapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @Binding var coffeeShops: [CoffeeShop]
    @Binding var selectedCoffeeShop: CoffeeShop?
    @Binding var centeredOnUser: Bool
    @Binding var userHasMoved: Bool
    @Binding var visibleRegionCenter: CLLocationCoordinate2D?
    @Binding var showUserLocationButton: Bool
    @Binding var isAnnotationSelected: Bool
    @Binding var mapTapped: Bool
    @Binding var showBrewPreview: Bool

    
    let DISTANCE = CLLocationDistance(2500)
    let batchUpdateSize = 10
    
    var previousRegion: MKCoordinateRegion?
    
    init(locationManager: LocationManager,
         coffeeShops: Binding<[CoffeeShop]>,
         selectedCoffeeShop: Binding<CoffeeShop?>,
         centeredOnUser: Binding<Bool>,
         userHasMoved: Binding<Bool>,
         visibleRegionCenter: Binding<CLLocationCoordinate2D?>,
         showUserLocationButton: Binding<Bool>,
         isAnnotationSelected: Binding<Bool>,
         mapTapped: Binding<Bool>,
         showBrewPreview: Binding<Bool>) {
        
        self.locationManager = locationManager
        self._coffeeShops = coffeeShops
        self._selectedCoffeeShop = selectedCoffeeShop
        self._centeredOnUser = centeredOnUser
        self._userHasMoved = userHasMoved
        self._visibleRegionCenter = visibleRegionCenter
        self._showUserLocationButton = showUserLocationButton
        self._isAnnotationSelected = isAnnotationSelected
        self._mapTapped = mapTapped
        self._showBrewPreview = showBrewPreview
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.mapTapped))
        tapRecognizer.delegate = context.coordinator as? any UIGestureRecognizerDelegate
        mapView.addGestureRecognizer(tapRecognizer)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        guard let userLocation = locationManager.userLocation else { return }

        if !locationManager.initialRegionSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                setRegion(to: userLocation.coordinate, on: mapView)
                self.locationManager.initialRegionSet = true
            }
        }

        if centeredOnUser {
            setRegion(to: userLocation.coordinate, on: mapView)
            centeredOnUser = false
            showUserLocationButton = false
        }
        
        // Update annotations only within visible map region
        let visibleMapRect = mapView.visibleMapRect
        let visibleAnnotations = mapView.annotations(in: visibleMapRect).compactMap { $0 as? MKPointAnnotation }

        let newAnnotations = self.coffeeShops.map(self.coffeeShopToAnnotation)
        
        let annotationsToRemove = visibleAnnotations.filter { old in
            !newAnnotations.contains { $0.coordinate.equalTo(old.coordinate) }
        }
        let annotationsToAdd = newAnnotations.filter { new in
            !visibleAnnotations.contains { $0.coordinate.equalTo(new.coordinate) }
        }

        updateAnnotations(for: mapView, annotationsToAdd: annotationsToAdd, annotationsToRemove: annotationsToRemove)

        if let selectedCoffeeShop = selectedCoffeeShop,
           let annotation = mapView.annotations.first(where: { $0.coordinate.latitude == selectedCoffeeShop.latitude && $0.coordinate.longitude == selectedCoffeeShop.longitude }) as? MKPointAnnotation {
            mapView.selectAnnotation(annotation, animated: true)
        }
    }

    func setRegion(to coordinate: CLLocationCoordinate2D, on mapView: MKMapView) {
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: DISTANCE, longitudinalMeters: DISTANCE)
        mapView.setRegion(region, animated: true)
    }
    
    func shouldLoadAnnotations(previousRegion: MKCoordinateRegion?, currentRegion: MKCoordinateRegion) -> Bool {
        guard let previousRegion = previousRegion else {
            // If there's no previous region, it means it's the first time we're checking.
            // In this case, we should load the annotations.
            return true
        }

        let previousCenter = CLLocation(latitude: previousRegion.center.latitude, longitude: previousRegion.center.longitude)
        let currentCenter = CLLocation(latitude: currentRegion.center.latitude, longitude: currentRegion.center.longitude)

        // Define the threshold distance (in meters)
        let thresholdDistance = CLLocationDistance(1000)

        return currentCenter.distance(from: previousCenter) > thresholdDistance
    }

    private func updateAnnotations(for mapView: MKMapView, annotationsToAdd: [MKPointAnnotation], annotationsToRemove: [MKPointAnnotation]) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Batch adding annotations to avoid lagging UI.
            let annotationsToAddBatched = annotationsToAdd.chunked(into: self.batchUpdateSize)

            DispatchQueue.main.async {
                mapView.removeAnnotations(annotationsToRemove)
                annotationsToAddBatched.forEach { batch in
                    mapView.addAnnotations(batch)
                }
            }
        }
    }


    private func coffeeShopToAnnotation(_ coffeeShop: CoffeeShop) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: coffeeShop.latitude, longitude: coffeeShop.longitude)
        annotation.title = coffeeShop.name
        return annotation
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var cancellable: AnyCancellable?
        private let userHasMovedSubject = PassthroughSubject<Bool, Never>()

        init(_ parent: MapView) {
              self.parent = parent
              super.init()
              self.cancellable = self.userHasMovedSubject
                  .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                  .removeDuplicates()
                  .sink { value in
                      parent.showUserLocationButton = value
                  }
          }
        
        @objc func mapTapped() {
            parent.mapTapped = true
        }

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            let currentRegion = mapView.region
            parent.visibleRegionCenter = currentRegion.center

            // Load new annotations only if the visible region significantly changes.
            if parent.shouldLoadAnnotations(previousRegion: parent.previousRegion, currentRegion: currentRegion) {
                parent.previousRegion = currentRegion

                let visibleMapRect = mapView.visibleMapRect
                let visibleAnnotations = mapView.annotations(in: visibleMapRect).compactMap { $0 as? MKPointAnnotation }

                let currentCoffeeShops = Set(parent.coffeeShops)
                
                let visibleCoffeeShops = Set(visibleAnnotations.compactMap { visibleAnnotation in
                    return parent.coffeeShops.first(where: { $0.latitude == visibleAnnotation.coordinate.latitude && $0.longitude == visibleAnnotation.coordinate.longitude })
                })

                let coffeeShopsToAdd = currentCoffeeShops.subtracting(visibleCoffeeShops)
                let coffeeShopsToRemove = visibleCoffeeShops.subtracting(currentCoffeeShops)

                let annotationsToAdd = coffeeShopsToAdd.map(parent.coffeeShopToAnnotation)
                let annotationsToRemove = coffeeShopsToRemove.map(parent.coffeeShopToAnnotation)

                parent.updateAnnotations(for: mapView, annotationsToAdd: annotationsToAdd, annotationsToRemove: annotationsToRemove)
            }

            let userLocation = parent.locationManager.userLocation?.coordinate
            let distanceFromUser = currentRegion.center.distance(from: userLocation)
            parent.userHasMoved = distanceFromUser > parent.DISTANCE / 2
        }



        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let coffeeShop = parent.coffeeShops.first(where: { $0.latitude == view.annotation?.coordinate.latitude && $0.longitude == view.annotation?.coordinate.longitude }) {
                parent.selectedCoffeeShop = coffeeShop
                parent.showBrewPreview = true
            }
        }
    }
}

extension CLLocationCoordinate2D {
    func distance(from coordinate: CLLocationCoordinate2D?) -> CLLocationDistance {
        guard let coordinate = coordinate else { return .greatestFiniteMagnitude }
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }

    func equalTo(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return self.latitude == coordinate.latitude && self.longitude == coordinate.longitude
    }
}
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
