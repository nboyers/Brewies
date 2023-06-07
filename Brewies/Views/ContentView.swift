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
    private var rewardAds = RewardAdController()
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
    @State private var bottomSheetPosition: BottomSheetPosition = .relative(0.17) // Starting position for bottomSheet
    @State private var userCredits: Int = 2
    @State private var showNoCreditsAlert = false
    @State private var showNoAdsAvailableAlert = false
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
            .alert(isPresented: $showNoCreditsAlert) {
                Alert(
                    title: Text("No Credits Left"),
                    message: Text("You have no credits left. Would you like to watch an ad to earn more?"),
                    primaryButton: .default(Text("Watch Ad")) {
                        // Assuming rewardAds is an instance of RewardAdController
                        let adsShown = rewardAds.show()
                        if adsShown {
                            userCredits += 1
                        } else {
                            // If there are no ads available, show the alert
                            showNoAdsAvailableAlert = true
                        }
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
            .alert(isPresented: $showNoAdsAvailableAlert) {
                Alert(
                    title: Text("No Ads Available"),
                    message: Text("There are currently no ads available. Please try again later."),
                    dismissButton: .default(Text("OK"))
                )
            }
            
            .bottomSheet(bottomSheetPosition: self.$bottomSheetPosition, switchablePositions: [
                .relativeBottom(0.17), //Floor
                .relative(0.55), // Mid swipe
                .relativeTop(0.95) //Top full swipe
            ], headerContent: { // the top portion
                HStack {
                    Button(action: {
                        
                        //TODO: Work on adding a credit system to incentives users to watch ads
                        if userCredits > 0 {
                            fetchCoffeeShops()
                            userCredits -= 1
                        } else {
                            showNoCreditsAlert = true
                        }
                        
                    }) {
                        Text("Search Area")
                            .padding(.vertical, 10)
                            .padding(.horizontal, 70)
                            .font(.title3)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .foregroundColor(.white)
                            .background(.secondary)
                            .cornerRadius(40)
                    }
                    Text("Credits: \(userCredits)")
                    
                }
            }) {
                if selectedCoffeeShop != nil && showBrewPreview {
                    BrewPreviewList(coffeeShops: $coffeeShops, selectedCoffeeShop: $selectedCoffeeShop, showBrewPreview: $showBrewPreview)
                }
                AdBannerView()
                    .frame(width: 320, height: 50)
                
                
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
    
    
    
    //MARK: Func to retrieve the cafe's from the APIs
    private func fetchCoffeeShops() {
        guard let centerCoordinate = visibleRegionCenter ?? locationManager.getCurrentLocation() else {
            showAlert = true
            return
        }
        
        if let cachedCoffeeShops = UserCache.shared.getCachedCoffeeShops(for: centerCoordinate) {
            self.coffeeShops = cachedCoffeeShops
            self.selectedCoffeeShop = cachedCoffeeShops.first // Set selectedCoffeeShop to first one
            showBrewPreview = true
        } else {
            let yelpAPI = YelpAPI()
            yelpAPI.fetchIndependentCoffeeShops(
                latitude: centerCoordinate.latitude,
                longitude: centerCoordinate.longitude
            ) { coffeeShops in
                self.coffeeShops = coffeeShops
                self.selectedCoffeeShop = coffeeShops.first // Set selectedCoffeeShop to first one
                showBrewPreview = true
                UserCache.shared.cacheCoffeeShops(coffeeShops, for: centerCoordinate)
            }
        }
    }
}
struct ContentView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

