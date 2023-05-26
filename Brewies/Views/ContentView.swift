//
//  ContentView.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.
//

import SwiftUI
import CoreLocation
import MapKit
import BottomSheet

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
    @State private var bottomSheetPosition: BottomSheetPosition = .relative(0.20) // Starting position for bottomSheet
    
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
                if showUserLocationButton {
                    GeometryReader { geo in
                        Button(action: {
                            centeredOnUser = true
                        }) {
                            Image(systemName: "location.square.fill")
                                .resizable()
                                .frame(width: 30, height: 30)

                                .imageScale(.large)
                                .background(Color.black.opacity(0.75))
                        }
                        .position(x: geo.size.width - 50, y: geo.size.height / 4)
                    }
                }
                
            }
            .bottomSheet(bottomSheetPosition: self.$bottomSheetPosition, switchablePositions: [
                .relativeBottom(0.20), //Floor
                .relative(0.4), // Mid swipe
                .relativeTop(0.75) //Top full swipe
            ], headerContent: { // the top portion
                HStack {
                    Spacer()
                    Button(action: {
                        fetchCoffeeShops()
                    }) {
                        Text("Search Area")
                            .padding(.vertical, 10)
                            .padding(.horizontal, 70)
                            .font(.title3)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .foregroundColor(.white)
                            .background(.secondary)
                            .cornerRadius(25)
                    }
    
                    Spacer()
                }
//                .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.quaternaryLabel)))
                .onTapGesture {
                    self.bottomSheetPosition = .relativeTop(0.6)
                }
            }) {
                if selectedCoffeeShop != nil && showBrewPreview {
                    BrewPreviewList(coffeeShops: $coffeeShops, selectedCoffeeShop: $selectedCoffeeShop, showBrewPreview: $showBrewPreview)
                }
            }
            .enableAppleScrollBehavior()
            .enableBackgroundBlur()
            .backgroundBlurMaterial(.systemDark)
            
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
