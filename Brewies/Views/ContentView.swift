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
import Introspect

struct ContentView: View {
//    @ObservedObject private var locationManager = LocationManager()
    @ObservedObject private var contentVM = ContentViewModel()
    
    @StateObject var user = User()
    @ObservedObject var yelpParams =  YelpSearchParams()
    
    @Environment(\.rootViewController) private var rootViewController: UIViewController?
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme (dark or light mode)
    
    private var rewardAds = RewardAdController()
    @State private var visibleRegionCenter: CLLocationCoordinate2D?

    @State private var bottomSheetPosition: BottomSheetPosition = .relative(0.20) // Starting position for bottomSheet
//    @State private var userCredits: Int = 10
    @State private var mapView = MKMapView()
    @State private var showAlert = false
    @State private var centeredOnUser = false
    @State private var showingBrewPreviewList = false
    @State private var userHasMoved = false
    @State private var showUserLocationButton = false
    @State private var isAnnotationSelected = false
    @State private var mapTapped = false
    @State private var showNoCreditsAlert = false
    @State private var showingUserProfile = false
    @State private var showingFilterView = false
    @State private var shouldSearchInArea = false
    
    @State var searchedLocation: CLLocationCoordinate2D?
    @State private var selectedRadiusIndex: Int = 0 // Default index to 0
    private let radiusOptions = [8047, 16093, 24140, 32186] // Radius in meters
    
    @State private var searchQuery: String = ""
//    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @FocusState var isInputActive: Bool

    private var rewardAd = RewardAdController()
    let DISTANCE = CLLocationDistance(2500)
    
    let signInCoordinator = SignInWithAppleCoordinator()
    
    
    var body: some View {
        TabView {
            ZStack {
                MapView(
                    locationManager: contentVM.locationManager,
                    coffeeShops: $contentVM.coffeeShops,
                    selectedCoffeeShop: $contentVM.selectedCoffeeShop,
                    centeredOnUser: $centeredOnUser,
                    mapView: $mapView,
                    userHasMoved: $userHasMoved,
                    visibleRegionCenter: $visibleRegionCenter,
                    showUserLocationButton: $showUserLocationButton,
                    isAnnotationSelected: $isAnnotationSelected,
                    mapTapped: $mapTapped,
                    showBrewPreview: $contentVM.showBrewPreview,
                    searchedLocation: $searchedLocation,
                    searchQuery: $searchQuery,
                    shouldSearchInArea: $shouldSearchInArea
                )
                .onAppear {
                    contentVM.locationManager.requestLocationAccess()
                    rewardAd.requestIDFA()
                    print(contentVM.coffeeShops)
                }
                
                .sheet(isPresented: $showingFilterView) {
                    FiltersView(yelpParams: yelpParams, visibleRegionCenter: visibleRegionCenter)
                        .environmentObject(user)
                }
                
                GeometryReader { geo in
                    Button(action: {
                        contentVM.fetchCoffeeShops(using: nil, visibleRegionCenter: visibleRegionCenter)
                       
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
                            Image(systemName: "location.square.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(Color.primary)
                                .background(
                                    Rectangle()
                                        .fill(Color.accentColor)
                                )
                        }
                        .offset(CGSize(width: geo.size.width/10, height: geo.size.width*1.55))
                    }
                }
            }
            
            //MARK: ALERTS
            .alert(isPresented: $contentVM.showNoAdsAvailableAlert) {
                Alert(
                    title: Text("No Ads Available"),
                    message: Text("There are currently no ads available. Please try again later."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $contentVM.showNoCoffeeShopsAlert) {
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
                    Spacer()
                    HStack(alignment: .center, spacing: 10) {
                        Button(action: {
                            showingFilterView = true
                        }) {
                            Image(systemName: "ellipsis.circle")
                                .resizable()
                                .foregroundColor(Color.accentColor)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }.padding(.horizontal)
                        
                        
                        TextField("Search Location", text: $searchQuery, onEditingChanged: { isEditing in
                            if isEditing {
                                isSearching = true
                                bottomSheetPosition = .relative(0.70)
                            }
                        }, onCommit: {
                            searchLocation(for: searchQuery)
                        })
                        .focused($isInputActive)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 270, height: 20)
                        
                        
                        //MARK: Profile / Cancel Button
                        Button(action: {
                            if isSearching {
                                searchQuery = ""
                                isInputActive = false
                                isSearching = false
                                bottomSheetPosition = .relativeBottom(0.20)
                                
                            } else {
                                bottomSheetPosition = .relativeBottom(0.20)
                                showingUserProfile = true
                            }
                        }) {
                            if !isSearching {
                                if !user.isLoggedIn {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .foregroundColor(Color.accentColor)
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                    
                                } else {
                                    Text(String(user.firstName.prefix(1)))
                                        .foregroundColor(.white)
                                        .font(.system(size: 30, weight: .bold))
                                        .frame(width: 30, height: 30)
                                        .background(RadialGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink]), center: .center, startRadius: 5, endRadius: 70))
                                        .clipShape(Circle())
                                    
                                }
                            } else {
                                Text("Cancel")
                                    .foregroundColor(Color.accentColor)
                                
                            }
                        }.padding(.horizontal)
                    }.padding(.vertical)
                    Spacer()
                }
            }) {
                ScrollView {
                    Divider()
                    
                    if contentVM.selectedCoffeeShop != nil && contentVM.showBrewPreview {
                        
                        HStack() {
                            GeometryReader { geo in
                                Text("\(contentVM.coffeeShops.count) Cafes In Map")
                                    .padding(.horizontal, geo.size.width*0.07)
                            }
                                Spacer()
                      
       
                        }
                        
                        BrewPreviewList(coffeeShops: $contentVM.coffeeShops,
                                        selectedCoffeeShop: $contentVM.selectedCoffeeShop,
                                        showBrewPreview: $contentVM.showBrewPreview)
                    }
                    AdBannerView()
                        .frame(width: 320, height: 50)
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
            
            FavoritesView(showPreview: $contentVM.showBrewPreview)
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Favorites")
                }
        }
    }
    
    
    
    // Function to search for a location by address
    func searchLocation(for address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            guard error == nil else {
                print("Geocoding error: \(error!.localizedDescription)")
                return
            }
            guard let placemark = placemarks?.first, let location = placemark.location else {
                print("No placemark found for address: \(address)")
                return
            }
            
            DispatchQueue.main.async {
                self.searchedLocation = location.coordinate
            }
        }
    }
    
    private  func convertMetersToMiles(meters: Int) -> Int {
        return Int(round(Double(meters) * 0.000621371))
    }
    
    
//    private func handleRewardAd() {
//        if let viewController = rootViewController {
//            rewardAd.present(from: viewController)
//            userCredits += 1
//        } else {
//            // If there is no root view controller available, show an alert
//            showNoAdsAvailableAlert = true
//        }
//    }
}
