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
    
    private var rewardAds = RewardAdController()
    @State private var coffeeShops: [CoffeeShop] = []
    @State private var showAlert = false
    @State private var selectedCoffeeShop: CoffeeShop?
    @State private var centeredOnUser = false
//    @State private var mapView = MKMapView()
    @State private var visibleRegionCenter: CLLocationCoordinate2D?
    @State private var showingBrewPreviewList = false
    @State private var userHasMoved = false
    @State private var showUserLocationButton = false
    @State private var isAnnotationSelected = false
    @State private var mapTapped = false
    @State private var showBrewPreview = false
    @State private var bottomSheetPosition: BottomSheetPosition = .relative(0.20) // Starting position for bottomSheet
    @State private var userCredits: Int = 1000
    @State private var showNoCreditsAlert = false
    @State private var showNoAdsAvailableAlert = false
    private var rewardAd = RewardAdController()
    let DISTANCE = CLLocationDistance(2500)
    var signInWithAppleCoordinator = SignInWithAppleCoordinator()
    
    
    var body: some View {
        TabView {
            ZStack {
                MapView(
                    locationManager: locationManager,
                    coffeeShops: $coffeeShops,
                    selectedCoffeeShop: $selectedCoffeeShop,
                    centeredOnUser: $centeredOnUser,
//                    mapView: $mapView,
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
                GeometryReader { geo in
                    Button(action: {
                        
                        //TODO: Work on adding a credit system to incentives users to watch ads
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
                //                .padding()
                
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
            .alert(isPresented: $showNoAdsAvailableAlert) {
                Alert(
                    title: Text("No Ads Available"),
                    message: Text("There are currently no ads available. Please try again later."),
                    dismissButton: .default(Text("OK"))
                )
            }
            
            .bottomSheet(bottomSheetPosition: self.$bottomSheetPosition, switchablePositions: [
                .relativeBottom(0.20), //Floor
                .relative(0.70), // Mid swipe
                .relativeTop(0.95) //Top full swipe
            ], headerContent: { // the top portion
                HStack {
                    Text("Credits: \(userCredits)")
                        .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        if user.isLoggedIn {
                            // Perform action when user is logged in
                            //TODO: Create the sheeet that gives the user account
                        } else {
                            signInWithAppleCoordinator.startSignInWithAppleFlow()
                        }
                    }) {
                        if !user.isLoggedIn {
                            // Assuming you have user.profilePicture as UIImage
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                                .padding()
                        } else {
                            Text(String(user.firstName.prefix(1)))
                                .foregroundColor(.white)
                                .font(.system(size: 30, weight: .bold))
                                .frame(width: 30, height: 30)
                                .background(RadialGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink]), center: .center, startRadius: 5, endRadius: 70))
                                .clipShape(Circle())
                            
                        }
                    }
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
            .onAppear {
                locationManager.requestLocationAccess()
                rewardAd.loadRewardedAd()
                
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
        // Moved the check if shops are in cache and API call to a background thread
        DispatchQueue.global(qos: .background).async {
            guard let centerCoordinate = visibleRegionCenter ?? locationManager.getCurrentLocation() else {
                DispatchQueue.main.async {
                    showAlert = true
                }
                return
            }
            
            if let cachedCoffeeShops = UserCache.shared.getCachedCoffeeShops(for: centerCoordinate) {
                DispatchQueue.main.async {
                    self.coffeeShops = cachedCoffeeShops
                    self.selectedCoffeeShop = cachedCoffeeShops.first
                    showBrewPreview = true
                }
            } else {
                let yelpAPI = YelpAPI()
                yelpAPI.fetchIndependentCoffeeShops(
                    latitude: centerCoordinate.latitude,
                    longitude: centerCoordinate.longitude
                ) { coffeeShops in
                    DispatchQueue.main.async {
                        self.coffeeShops = coffeeShops
                        self.selectedCoffeeShop = coffeeShops.first
                        showBrewPreview = true
                    }
                    UserCache.shared.cacheCoffeeShops(coffeeShops, for: centerCoordinate)
                }
            }
        }
    }
    private func handleRewardAd() {
        rewardAd.requestIDFA()
        let adsShown = rewardAds.show()
        if adsShown {
            userCredits += 1
        } else {
            // If there are no ads available, show the alert
            showNoAdsAvailableAlert = true
        }
    }
}
    
//
//    func performSignInWithApple() {
//        // Create an instance of ASAuthorizationAppleIDProvider
//        let appleIDProvider = ASAuthorizationAppleIDProvider()
//
//        // Create an instance of ASAuthorizationRequest
//        let request = appleIDProvider.createRequest()
//        request.requestedScopes = [.fullName, .email] // Customize the requested scopes if needed
//
//        // Create an instance of ASAuthorizationController
//        let controller = ASAuthorizationController(authorizationRequests: [request])
//        controller.delegate = signInWithAppleCoordinator // Set the delegate to handle authorization callbacks
//        controller.presentationContextProvider = signInWithAppleCoordinator
//        controller.performRequests() // Initiate the sign-in flow
//    }
//}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

