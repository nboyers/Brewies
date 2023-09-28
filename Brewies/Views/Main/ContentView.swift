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
    @ObservedObject var storeKit = StoreKitManager()
    @ObservedObject var locationManager = LocationManager()
    
    private var rewardAd = RewardAdController()
    let signInCoordinator = SignInWithAppleCoordinator()
    
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme (dark or light mode)
    @EnvironmentObject var sharedVM: SharedViewModel
    
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var yelpParams: YelpSearchParams
    @EnvironmentObject var contentVM: ContentViewModel
    @EnvironmentObject var sharedAlertVM: SharedAlertViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var visibleRegionCenter: CLLocationCoordinate2D?
    @State private var activeSheet: ActiveSheet?
    
    @State private var mapView = MKMapView()
    @State private var showLocationAccessAlert = false
    @State private var centeredOnUser = false
    @State private var showingBrewPreviewList = false
    @State private var userHasMoved = false
    @State private var showUserLocationButton = false
    @State private var isAnnotationSelected = false
    @State private var mapTapped = false
    @State private var showNoCreditsAlert = false
    @State private var shouldSearchInArea = false
    @State var searchedLocation: CLLocationCoordinate2D?
    @State private var searchQuery: String = ""
    @State private var isSearching = false
    @State private var selectedCoffeeShop: CoffeeShop?
    
    
    
    
    
    @FocusState var isInputActive: Bool
    
    let DISTANCE = CLLocationDistance(2500)
    
    var body: some View {
        TabView {
            ZStack {
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
                    // 2. User Location Button
                    if showUserLocationButton {
                        GeometryReader { geo in
                            if !locationManager.isLocationAccessGranted {
                                // User has not granted location access, show Finder button
                                Button(action: {
                                    // Show the alert when the button is pressed
                                    showLocationAccessAlert = true
                                }) {
                                    Image(systemName: "questionmark.app.fill")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(Color.primary)
                                        .background(
                                            Rectangle()
                                                .fill(Color.accentColor)
                                        )
                                }
                                .offset(CGSize(width: geo.size.width/10, height: geo.size.width*1.55))
                            } else {
                                // User has granted location access, show existing location button
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
                }
                
                //MARK: BREW PREVIEW
                .bottomSheet(bottomSheetPosition: self.$sharedVM.bottomSheetPosition, switchablePositions: [
                    .relativeBottom(0.20), //Floor
                    .relative(0.70), // Mid swipe
                    .relativeTop(0.80) //Top full swipe
                ], headerContent: { // the top portion
                    HStack {
                        Spacer()
                        HStack(alignment: .center, spacing: 10) {
                            Button(action: {
                                activeSheet = .filter
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
                                    sharedVM.bottomSheetPosition = .relative(0.70)
                                }
                            }, onCommit: {
                                searchLocation(for: searchQuery)
                            })
                            .focused($isInputActive)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .foregroundColor(.primary) // Use primary color for text to adapt to light/dark mode
                            
                            //MARK: Profile / Cancel Button
                            Button(action: {
                                if isSearching {
                                    searchQuery = ""
                                    isInputActive = false
                                    isSearching = false
                                    sharedVM.bottomSheetPosition = .relativeBottom(0.20)
                                } else {
                                    sharedVM.bottomSheetPosition = .relativeBottom(0.20)
                                    if userVM.user.isLoggedIn {
                                        // If user is logged in, show user profile view
                                        activeSheet = .userProfile
                                        
                                    } else {
                                        activeSheet = .signUpWithApple
                                        
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
                                            showBrewPreview: $contentVM.showBrewPreview,
                                            activeSheet: $activeSheet)
                            
                        }
                        if !storeKit.isAdRemovalPurchased && !userVM.user.isSubscribed {
                            AdBannerView()
                                .frame(width: 320, height: 50)
                        }
                        
                        Button(action: {
                            // Your action to handle the ad goes here
                            self.contentVM.handleRewardAd(reward: "credits")
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
                
                GeometryReader { geo in
                    VStack {
                        Button(action: {
                            // Check if the user has enough credits to perform a search
                            if userVM.user.credits > 0 {
                                // Perform the search
                                contentVM.fetchCoffeeShops(visibleRegionCenter: visibleRegionCenter)
                                
                            } else {
                                // When you want to show the "Insufficient Credits" alert
                                sharedAlertVM.currentAlertType = .insufficientCredits
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
                            activeSheet = .storefront
                            
                        }) {
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
                    
                    .offset(CGSize(width: geo.size.width*0.25, height: geo.size.width/6))
                }
                if let alertType = sharedAlertVM.currentAlertType {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    
                    CustomAlertView(
                        title: alertType == .maxFavoritesReached ? "Maximum Favorites Reached" : "Insufficient Credits",
                        message: alertType == .maxFavoritesReached ? "Watch an ad to unlock more favorite slots or go to the store." : "Watch an ad or click the credits to buy more from the store.",
                        goToStoreAction: {
                            // Your action for going to the store
                            activeSheet = .storefront
                            sharedAlertVM.currentAlertType = nil
                            sharedAlertVM.showCustomAlert = false
                        },
                        watchAdAction: {
                            self.contentVM.handleRewardAd(reward: alertType == .maxFavoritesReached ? "favorites" : "credits")
                            // Your action for watching an ad
                            sharedAlertVM.currentAlertType = nil
                            sharedAlertVM.showCustomAlert = false
                        },
                        dismissAction: {
                            sharedAlertVM.currentAlertType = nil
                            sharedAlertVM.showCustomAlert = false
                        }
                    )
                }
            }
            //MARK: User Profile
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .settings:
                    SettingsView()
                    
                case .filter:
                    FiltersView(yelpParams: yelpParams, contentVM: contentVM, visibleRegionCenter: visibleRegionCenter)
                        .environmentObject(userVM)
                    
                case .userProfile:
                    UserProfileView(userViewModel: userVM, contentViewModel: contentVM, activeSheet: $activeSheet)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.medium])
                    
                case .signUpWithApple:
                    if userVM.user.isLoggedIn {
                        UserProfileView(userViewModel: userVM, contentViewModel: contentVM, activeSheet: $activeSheet)
                            .presentationDetents([.medium])
                    } else {
                        Spacer()
                        
                        GeometryReader { geometry in
                            VStack {
                                Spacer() // Pushes the content to the center vertically
                                HStack {
                                    Spacer() // Pushes the content to the center horizontally
                                    Image("Brewies_icon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5) // 50% of the width of the GeometryReader
                                        .clipped()
                                        .cornerRadius(10)
                                    Spacer() // Pushes the content to the center horizontally
                                }
                                Spacer() // Pushes the content to the center vertically
                            }
                        }
                        Spacer()
                        SignInWithAppleButton(action: {
                            signInCoordinator.startSignInWithAppleFlow()
                        }, label: "Sign in with Apple")
                        .frame(width: 280, height: 45)
                        .padding([.top, .bottom], 50)
                        .presentationDetents([.medium])
                        
                    }
                    
                case .storefront:
                    StorefrontView()
                    
                case .detailBrew:
                    if let selectedCoffeeShop = selectedCoffeeShop {
                        BrewDetailView(coffeeShop: selectedCoffeeShop, selectedCoffeeShop: $selectedCoffeeShop)
                    } else {
                        EmptyView()
                    }
                    
                case .safariView:
                    if let url = URL(string: selectedCoffeeShop?.url ?? "https://nobosoftware.com") {
                        SafariView(url: url)
                    }
                }
            }
            .alert(isPresented: $showLocationAccessAlert) {
                Alert(
                    title: Text("Location Access Required"),
                    message: Text("To give local recommendations, Brewies needs access to your location. Please go to Settings > Privacy > Location Services, find Brewies, and allow location access."),
                    dismissButton: .default(Text("OK"))
                )
            }
            
            .edgesIgnoringSafeArea(.top)
            .tabItem {
                Image(systemName: "map")
                Text("Map")
            }
            
            FavoritesView(showPreview: $contentVM.showBrewPreview, activeSheet: $activeSheet)
                .environmentObject(userVM)
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

