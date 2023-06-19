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
import AuthenticationServices


struct ContentView: View {
    @ObservedObject private var locationManager = LocationManager()
    @ObservedObject var user = User()
    @Environment(\.rootViewController) private var rootViewController: UIViewController?

    private var rewardAds = RewardAdController()
    @State private var coffeeShops: [CoffeeShop] = []
    @State private var showAlert = false
    @State private var selectedCoffeeShop: CoffeeShop?
    @State private var centeredOnUser = false
    @State private var visibleRegionCenter: CLLocationCoordinate2D?
    @State private var showingBrewPreviewList = false
    @State private var userHasMoved = false
    @State private var showUserLocationButton = false
    @State private var isAnnotationSelected = false
    @State private var mapTapped = false
    @State private var showBrewPreview = false
    @State private var bottomSheetPosition: BottomSheetPosition = .relative(0.20) // Starting position for bottomSheet
    @State private var userCredits: Int = 10
    @State private var mapView = MKMapView()
    @State private var showNoCreditsAlert = false
    @State private var showNoAdsAvailableAlert = false
    @State private var showNoCoffeeShopsAlert = false
    @State private var showingUserProfile = false
    
    private var rewardAd = RewardAdController()
    let DISTANCE = CLLocationDistance(2500)

    let signInCoordinator = SignInWithAppleCoordinator()


    
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
                .onAppear {
                    locationManager.requestLocationAccess()
                    rewardAd.requestIDFA()
                    fetchCoffeeShops()
                }
                
                GeometryReader { geo in
                    Button(action: {
                        if userCredits > 0 {
                            fetchCoffeeShops()
                            userCredits -= 1
                        } else {
                            showNoCreditsAlert = true
                            
                        }
                        
                    }) {
                        Text("Search this area")
                            .font(.system(size: 20, weight: .bold))
                            .frame(width: geo.size.width/2.5, height: geo.size.width/50)
                            .padding()
                            .font(.title3)
                            .foregroundColor(.black)
                            .background(.white)
                    }
                    .cornerRadius(10)
                    .offset(CGSize(width: geo.size.width*0.25, height: geo.size.width/6))
                    .shadow(radius: 50)
                }
                
                if showUserLocationButton {
                    GeometryReader { geo in
                        Button(action: {
                            centeredOnUser = true
                        }) {
                            Image(systemName: "location")
                                .resizable()
                            
                                .frame(width: 30, height: 30)
                                .imageScale(.large)
                                .background(Color.white)
                                .shadow(radius: 10)
                        }
                        .offset(CGSize(width: geo.size.width*0.75, height: geo.size.width/5.5))
                    }
                }
                
            }
            //MARK: ALERTS
            .alert(isPresented: $showNoAdsAvailableAlert) {
                Alert(
                    title: Text("No Ads Available"),
                    message: Text("There are currently no ads available. Please try again later."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showNoCoffeeShopsAlert) {
                Alert(
                    title: Text("No Coffee Shops Found"),
                    message: Text("We could not find any coffee shops in your area."),
                    dismissButton: .default(Text("OK"))
                )
            }

            
            //MARK: BREW PREVIEW
            .bottomSheet(bottomSheetPosition: self.$bottomSheetPosition, switchablePositions: [
                .relativeBottom(0.20), //Floor
                .relative(0.70), // Mid swipe
                .relativeTop(0.95) //Top full swipe
            ], headerContent: { // the top portion
                HStack {
                    Text("Credits: \(userCredits)")
                        .padding(5)
                    
                    Spacer()
                    
                    Button(action: {
                        showingUserProfile = true
                    }) {
                        if !user.isLoggedIn {
            
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundColor(Color.accentColor)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                                .padding(5)
                        } else {
                            Text(String(user.firstName.prefix(1)))
                                .foregroundColor(.white)
                                .font(.system(size: 30, weight: .bold))
                                .frame(width: 30, height: 30)
                                .background(RadialGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink]), center: .center, startRadius: 5, endRadius: 70))
                                .clipShape(Circle())
                        }
                    }.padding(10)
                }
            }) {
                
                Divider()
                
                if selectedCoffeeShop != nil && showBrewPreview {
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(coffeeShops.count) Cafes In Map")
                            .padding()
                        Spacer()
                    }
                    
                    BrewPreviewList(coffeeShops: $coffeeShops,
                                    selectedCoffeeShop: $selectedCoffeeShop,
                                    showBrewPreview: $showBrewPreview)
                }
                AdBannerView()
                    .frame(width: 320, height: 50)
                //TODO: Make this button work ; just not now
                Button(action: {
                    handleRewardAd()
                }) {
                    Text("Watch Ads")
                        .padding(.vertical, 10)
                        .padding(.horizontal, 70)
                        .font(.title3)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .foregroundColor(.white)
                        .background(.secondary)
                        .cornerRadius(40)
                }
                
            }
            .enableAppleScrollBehavior()
            .enableBackgroundBlur()
            .backgroundBlurMaterial(.systemDark)
            
            //MARK: User Profile
            .sheet(isPresented: $showingUserProfile) {
                GeometryReader { geo in
                    VStack {
                        HStack() {
                            Button(action: {
                                print("TODO: Handle settings button")
                            }) {
                                Image(systemName: "gear")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.primary)
                                    .padding()
                            }
                            Spacer()
                            
                            Button(action: {
                                showingUserProfile = false
                            }) {
                                Image(systemName: "x.circle.fill")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.primary)
                                    .padding()
                            }
                        }
                        Spacer()
                        SignInWithAppleButton(action: {
                            signInCoordinator.startSignInWithAppleFlow()
                        }, label: "Sign in with Apple")
                        .frame(width: 280, height: 45)
                        .padding(.top, 50)
                    }
                }
                
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.medium, .large])
            } //end user sheet
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
    
    
    // MARK: FUNCTIONS
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
                if coffeeShops.isEmpty {
                    self.showNoCoffeeShopsAlert = true
                } else {
                    self.coffeeShops = coffeeShops
                    self.selectedCoffeeShop = coffeeShops.first // Set selectedCoffeeShop to first one
                    showBrewPreview = true
                    UserCache.shared.cacheCoffeeShops(coffeeShops, for: centerCoordinate)
                }
            }
        }
    }

    
    
    private func handleRewardAd() {
        if let viewController = rootViewController {
            rewardAd.present(from: viewController)
            userCredits += 1
        } else {
            // If there is no root view controller available, show an alert
            showNoAdsAvailableAlert = true
        }
    }
}
