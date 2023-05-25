//
//  ContentView.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.
//

import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    @ObservedObject private var locationManager = LocationManager()
    @State private var coffeeShops: [CoffeeShop] = []
    @State private var showAlert = false
    @State private var selectedCoffeeShop: CoffeeShop?
    @State private var centeredOnUser = false
    @State private var mapView = MKMapView()
    @State private var visibleRegionCenter: CLLocationCoordinate2D?
    @State private var showingBrewPreviewList = false
    @State private var userHasMoved = false
    @State private var showUserLocationButton = false
    @State private var isAnnotationSelected = false
    @State private var mapTapped = false
    @State private var showBrewPreview = false

    let DISTANCE = CLLocationDistance(2000)
    
    var body: some View {
        TabView {
            ZStack {
                MapView(
                    locationManager: locationManager,
                    coffeeShops: $coffeeShops,
                    selectedCoffeeShop: $selectedCoffeeShop,
                    centeredOnUser: $centeredOnUser,
                    mapView: $mapView,
                    userHasMoved: $userHasMoved,
                    visibleRegionCenter: $visibleRegionCenter,
                    showUserLocationButton: $showUserLocationButton,
                    isAnnotationSelected: $isAnnotationSelected,
                    mapTapped: $mapTapped,
                    showBrewPreview: $showBrewPreview
                )
                .onAppear(perform: {
                    fetchCoffeeShops()
                })
                
                VStack {
                    Spacer().frame(height: 75)
                    
                    Button(action: {
                        fetchCoffeeShops()
                    }) {
                        Text("Search Area")
                            .frame(width: 175, height: 10)
                            .font(.title3)
                            .padding(20)
                            .foregroundColor(.white)
                            .background(.secondary)
                            .cornerRadius(25)
                    }
                    
                    Spacer()
                    
                    if selectedCoffeeShop != nil && showBrewPreview {
                        BrewPreviewList(
                            coffeeShops: $coffeeShops,
                            selectedCoffeeShop: $selectedCoffeeShop,
                            showBrewPreview: $showBrewPreview
                        )
                    }
                    
                    Spacer().frame(height: 100)
                }
                
                if showUserLocationButton {
                    GeometryReader { geo in
                        Button(action: {
                            centeredOnUser = true
                        }) {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.primary)
                                .imageScale(.large)
                                .padding()
                                .background(Color.white.opacity(0.75))
                                .clipShape(Circle())
                        }
                        .position(x: geo.size.width - 375, y: geo.size.height - 60)
                    }
                }
            }
            .onAppear {
                locationManager.requestLocationAccess()
            }
            .edgesIgnoringSafeArea(.top)
            .tabItem {
                Image(systemName: "map")
                Text("Map")
            }
            
            FavoritesView(showPreview: $showBrewPreview)
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Favorites")
                }
        }
    }
    
    private func fetchCoffeeShops() {
        guard let centerCoordinate = visibleRegionCenter ?? locationManager.getCurrentLocation() else {
            showAlert = true
            return
        }
        
        if let cachedCoffeeShops = UserCache.shared.getCachedCoffeeShops(for: centerCoordinate) {
            self.coffeeShops = cachedCoffeeShops
        } else {
            let yelpAPI = YelpAPI()
            yelpAPI.fetchIndependentCoffeeShops(
                latitude: centerCoordinate.latitude,
                longitude: centerCoordinate.longitude
            ) { coffeeShops in
                self.coffeeShops = coffeeShops
                UserCache.shared.cacheCoffeeShops(coffeeShops, for: centerCoordinate)
            }
        }
    }
}
