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


//FIXME: THe cancel button UI
//FIXME: Credits button is broken (Not pulling up sheet)
//FIXME: Website Button in preview is broken

struct ContentView: View {
    @ObservedObject var storeKit = StoreKitManager()
    
    private var rewardAd = RewardAdController()
    
    @Environment(\.rootViewController) private var rootViewController: UIViewController?
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme (dark or light mode)
    
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var yelpParams: YelpSearchParams
    @EnvironmentObject var contentVM: ContentViewModel

    @State private var visibleRegionCenter: CLLocationCoordinate2D?
    @State private var bottomSheetPosition: BottomSheetPosition = .relative(0.20) // Starting position for bottomSheet
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
    @State private var showSignUpWithApple = false
    @State private var showingStorefront = false
    @State var searchedLocation: CLLocationCoordinate2D?
    @State private var searchQuery: String = ""
    @State private var isSearching = false
    
    @FocusState var isInputActive: Bool
    
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
                .alert(isPresented: $contentVM.showNoCoffeeShopsAlert) {
                    Alert(
                        title: Text("No Coffee Shops Found"),
                        message: Text("We could not find any coffee shops in your area."),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .alert(isPresented: $contentVM.showNoAdsAvailableAlert) {
                    Alert(
                        title: Text("No Ads Available"),
                        message: Text("There are currently no ads available. Please try again later."),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .onAppear {
                    contentVM.locationManager.requestLocationAccess()

                }
                
                .sheet(isPresented: $showingFilterView) {
                    FiltersView(yelpParams: yelpParams, contentVM: contentVM, visibleRegionCenter: visibleRegionCenter)
                        .environmentObject(userVM)
                }
                
                GeometryReader { geo in
                    VStack {
                        Button(action: {
                            // Check if the user has enough credits to perform a search
                            if userVM.user.credits > 0 {
                                // Perform the search
                                contentVM.fetchCoffeeShops(visibleRegionCenter: visibleRegionCenter)
                            } else {
                                // If the user does not have enough credits, display an alert
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
                        .shadow(radius: 50)
                        
                        Button(action: {
                            showingStorefront = true
                        }) {//width: geo.size.width/3, height: geo.size.width/15)
                            Text("Discover Credits: \(userVM.user.credits)")
                                .frame(minWidth: geo.size.width/3, idealWidth: geo.size.width/3, maxWidth: geo.size.width/3 + CGFloat(5 * String(userVM.user.credits).count), minHeight:geo.size.width/20, idealHeight: geo.size.width/20, maxHeight: geo.size.width/20)
                                .padding(5)
                                .background(.black)
                                .font(.caption)
                                .foregroundColor(Color.cyan)
                                .cornerRadius(10)
                                .shadow(radius: 50)
                                .minimumScaleFactor(0.5)

                        }
                        
                        
                    }
                    .sheet(isPresented: $showingStorefront) {
                        StorefrontView()
                    }
                    
                    //MARK: ALERTS
                    .alert(isPresented: $showNoCreditsAlert) {
                        Alert(
                            title: Text("Insufficient Credits"),
                            message: Text("Watch an ad or click the credits to buy more from the store."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                    .offset(CGSize(width: geo.size.width*0.25, height: geo.size.width/6))
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
                                if userVM.user.isLoggedIn {
                                    // If user is logged in, show user profile view
                                    showingUserProfile = true
                                } else {
                                    showSignUpWithApple = true
                                }
                            }
                        })
                        {
                            if !isSearching {
                                if !userVM.user.isLoggedIn {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .foregroundColor(Color.accentColor)
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                    
                                } else {
                                    Text(String(userVM.user.firstName.prefix(1)))
                                        .foregroundColor(.white)
                                        .font(.system(size: 30, weight: .bold))
                                        .frame(width: 30, height: 30)
                                        .background(RadialGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink]), center: .center, startRadius: 5, endRadius: 70))
                                        .clipShape(Circle())
                                    
                                }
                            } else {
                                Image(systemName: "x.circle.fill")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.primary)
                                    .padding()
                                
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
                    if !storeKit.isAdRemovalPurchased && !userVM.user.isSubscribed {
                        AdBannerView()
                            .frame(width: 320, height: 50)
                    }
                    
                    Button(action: {
                        // Your action to handle the ad goes here
                        self.contentVM.handleRewardAd()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "video.fill")
                                .resizable()
                                .scaledToFit() // Maintain aspect ratio
                                .frame(width: 20, height: 20) // Specify the size of the image
                                .foregroundColor(.white) // Color of the star
                                .padding(5) // Add some padding to give the image more room
                                .background(Color.blue) // Background color of the circle
                                .clipShape(Circle()) // Make the background a circle
                            Text("Watch Ads for Credits")
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .enableAppleScrollBehavior()
            .enableBackgroundBlur()
            .backgroundBlurMaterial(.systemDark)
            
            //MARK: User Profile
            .sheet(isPresented: $showSignUpWithApple) {
                        if userVM.user.isLoggedIn {
                            UserProfileView(userViewModel: userVM, contentViewModel: contentVM)
                                .presentationDetents([.medium])
                        } else {
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
                                            showSignUpWithApple = false
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
                }
            } //end user sheet
            
            .sheet(isPresented: $showingUserProfile) {
                UserProfileView(userViewModel: userVM, contentViewModel: contentVM)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.medium, .large])
            }
            
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
}
