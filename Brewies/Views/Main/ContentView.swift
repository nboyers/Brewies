//
//  ContentView.swift
//  Brewies
//
//  Created by Noah Boyers on 08/18/24.
//

import SwiftUI
import CoreLocation
import MapKit
import BottomSheet
import AuthenticationServices
import AppTrackingTransparency

struct ContentView: View {
    @ObservedObject var storeKit = StoreKitManager()
    @EnvironmentObject var sharedAlertVM: SharedAlertViewModel
    let signInCoordinator = SignInWithAppleCoordinator()
    
    @EnvironmentObject var sharedVM: SharedViewModel
    @EnvironmentObject var rewardAd: RewardAdController
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var contentVM: ContentViewModel
    @EnvironmentObject var selectedCoffeeShop: SelectedCoffeeShop
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var visibleRegionCenter: CLLocationCoordinate2D?
    @State private var activeSheet: ActiveSheet?
    @State private var showLocationAccessAlert = false
    @State private var centeredOnUser = false
    @State private var userHasMoved = false
    @State private var showUserLocationButton = false
    @State private var isCoffeeSelected = true
    
    let DISTANCE = CLLocationDistance(2500)
    
    var body: some View {
        TabView {
            Tab("Discover", systemImage: "map.fill") {
                DiscoverView(
                    locationManager: locationManager,
                    contentVM: contentVM,
                    userVM: userVM,
                    sharedAlertVM: sharedAlertVM,
                    selectedCoffeeShop: selectedCoffeeShop,
                    storeKit: storeKit,
                    rewardAd: rewardAd,
                    signInCoordinator: signInCoordinator,
                    activeSheet: $activeSheet,
                    showLocationAccessAlert: $showLocationAccessAlert
                )
                .environmentObject(sharedAlertVM)
            }
            
            Tab("Favorites", systemImage: "heart.fill") {
                FavoritesView(showPreview: $contentVM.showBrewPreview, activeSheet: $activeSheet)
                    .environmentObject(rewardAd)
                    .environmentObject(userVM)
            }
        }
        .alert(isPresented: $showLocationAccessAlert) {
            Alert(
                title: Text("Location Access Required"),
                message: Text("To give local recommendations, Brewies needs access to your location. You can enable location services for Brewies in the Settings app."),
                primaryButton: .default(Text("Settings"), action: {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }),
                secondaryButton: .cancel()
            )
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .filter:
                FiltersView(googlePlacesParams: GooglePlacesSearchParams(), contentVM: contentVM, visibleRegionCenter: visibleRegionCenter)
                    .environmentObject(userVM)
                    .environmentObject(sharedAlertVM)
                
            case .userProfile:
                UserProfileSheetView(userVM: userVM, contentVM: contentVM)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.medium])
                
            case .signUpWithApple:
                if userVM.user.isLoggedIn {
                    UserProfileSheetView(userVM: userVM, contentVM: contentVM)
                        .presentationDetents([.medium])
                } else {
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
                if let coffeeShop = selectedCoffeeShop.coffeeShop {
                    BrewDetailView(coffeeShop: coffeeShop)
                }
                
            case .shareApp:
                ShareSheet(activityItems: ["Share Brewies", URL(string: "https://apps.apple.com/us/app/brewies/id6450864433")!])
                    .presentationDetents([.medium])
                    
            case .searchResults:
                VStack(spacing: 0) {
                    // Compact header for small detent
                    HStack {
                        Text("\(contentVM.brewLocations.count) \(isCoffeeSelected ? "Coffee Shops" : "Breweries") Found")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Button("✕") {
                            contentVM.showBrewPreview = false
                            activeSheet = nil
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    
                    NavigationView {
                        List {
                            ForEach(contentVM.brewLocations, id: \.id) { location in
                            Button(action: {
                                contentVM.selectedBrewLocation = location
                                selectedCoffeeShop.coffeeShop = location
                                activeSheet = .detailBrew
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(location.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        if let address = location.address, !address.isEmpty {
                                            Text(address)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                        
                                        HStack(spacing: 4) {
                                            ForEach(0..<5) { star in
                                                Image(systemName: star < Int(location.rating ?? 0) ? "star.fill" : "star")
                                                    .foregroundColor(.orange)
                                                    .font(.caption)
                                            }
                                            Text(String(format: "%.1f", location.rating ?? 0.0))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .navigationTitle("\(contentVM.brewLocations.count) \(isCoffeeSelected ? "Coffee Shops" : "Breweries")")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                contentVM.showBrewPreview = false
                                activeSheet = nil
                            }
                            }
                        }
                        .navigationBarHidden(true)
                    }
                }
                .presentationDetents([.height(80), .fraction(0.25), .medium, .large], selection: .constant(.fraction(0.25)))
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.25)))
                .interactiveDismissDisabled()
            }
        }
    }
}

struct DiscoverView: View {
    let locationManager: LocationManager
    let contentVM: ContentViewModel
    let userVM: UserViewModel
    let sharedAlertVM: SharedAlertViewModel
    let selectedCoffeeShop: SelectedCoffeeShop
    let storeKit: StoreKitManager
    let rewardAd: RewardAdController
    let signInCoordinator: SignInWithAppleCoordinator
    @Binding var activeSheet: ActiveSheet?
    @Binding var showLocationAccessAlert: Bool
    
    @State private var visibleRegionCenter: CLLocationCoordinate2D?
    @State private var centeredOnUser = false
    @State private var userHasMoved = false
    @State private var showUserLocationButton = false
    @State private var isCoffeeSelected = true
    
    var body: some View {
        let mapView = MapView(
            locationManager: locationManager,
            coffeeShops: .constant(contentVM.brewLocations),
            selectedCoffeeShop: .constant(contentVM.selectedBrewLocation),
            centeredOnUser: $centeredOnUser,
            userHasMoved: $userHasMoved,
            visibleRegionCenter: $visibleRegionCenter,
            showUserLocationButton: $showUserLocationButton,
            isAnnotationSelected: .constant(false),
            mapTapped: .constant(false),
            showBrewPreview: .constant(contentVM.showBrewPreview),
            searchedLocation: .constant(nil),
            searchQuery: .constant(""),
            shouldSearchInArea: .constant(false)
        )
        
        ZStack {
            mapView
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        sharedAlertVM.currentAlertType = .earnCredits
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.blue)
                            Text("\(userVM.user.credits)")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        activeSheet = userVM.user.isLoggedIn ? .userProfile : .signUpWithApple
                    }) {
                        if userVM.user.isLoggedIn {
                            Text(String(userVM.user.firstName.prefix(1)))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.blue, in: Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
            }
            
            if showUserLocationButton {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            if locationManager.isLocationAccessGranted {
                                centeredOnUser = true
                            } else {
                                showLocationAccessAlert = true
                            }
                        }) {
                            Image(systemName: locationManager.isLocationAccessGranted ? "location.fill" : "location.slash")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(locationManager.isLocationAccessGranted ? Color.blue : Color.red, in: Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 120)
                    }
                }
            }
            
            BottomControlPanel(
                isCoffeeSelected: $isCoffeeSelected,
                locationManager: locationManager,
                centeredOnUser: $centeredOnUser,
                showLocationAccessAlert: $showLocationAccessAlert,
                activeSheet: $activeSheet,
                userVM: userVM,
                contentVM: contentVM,
                visibleRegionCenter: visibleRegionCenter
            )
            

            
            if sharedAlertVM.currentAlertType != nil {
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.all)
                
                switch sharedAlertVM.currentAlertType {
                case .maxFavoritesReached:
                    CustomAlertView(
                        title: "Favorites Limit Reached",
                        message: "Upgrade your account to save more locations or watch an advertisement.",
                        primaryButtonTitle: "Upgrade Account",
                        primaryAction: {
                            activeSheet = .storefront
                            sharedAlertVM.currentAlertType = nil
                        },
                        secondaryButtonTitle: "Watch Ad",
                        secondaryAction: {
                            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                                ATTrackingManager.requestTrackingAuthorization { status in
                                    contentVM.handleRewardAd(reward: "favorites", rewardAdController: rewardAd)
                                }
                            } else {
                                contentVM.handleRewardAd(reward: "favorites", rewardAdController: rewardAd)
                                sharedAlertVM.currentAlertType = nil
                            }
                        },
                        dismissAction: {
                            sharedAlertVM.currentAlertType = nil
                        })
                    
                case .insufficientCredits:
                    CustomAlertView(
                        title: "Search Credits Required",
                        message: "Purchase additional search credits or watch an advertisement to continue.",
                        primaryButtonTitle: "Watch Advertisement",
                        primaryAction: {
                            print("Watch Ad button tapped")
                            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                                ATTrackingManager.requestTrackingAuthorization { status in
                                    contentVM.handleRewardAd(reward: "credits", rewardAdController: rewardAd)
                                }
                            } else {
                                contentVM.handleRewardAd(reward: "credits", rewardAdController: rewardAd)
                                sharedAlertVM.currentAlertType = nil
                            }
                        },
                        secondaryButtonTitle: "Purchase Credits",
                        secondaryAction: {
                            print("Purchase Credits button tapped")
                            activeSheet = .storefront
                            sharedAlertVM.currentAlertType = nil
                        },
                        dismissAction: {
                            print("X button tapped - dismissing alert")
                            DispatchQueue.main.async {
                                sharedAlertVM.currentAlertType = nil
                            }
                            print("Alert dismissed, currentAlertType: \(String(describing: sharedAlertVM.currentAlertType))")
                        })
                    
                case .noAdsAvailableAlert:
                    CustomAlertView(
                        title: "Advertisement Unavailable",
                        message: "No advertisements are currently available. Please try again later.",
                        primaryButtonTitle: "OK",
                        primaryAction: {
                            sharedAlertVM.currentAlertType = nil
                            DispatchQueue.global(qos: .background).async {
                                rewardAd.loadRewardedAd()
                            }
                        },
                        dismissAction: {
                            sharedAlertVM.currentAlertType = nil
                            DispatchQueue.global(qos: .background).async {
                                rewardAd.loadRewardedAd()
                            }
                        }
                    )
                    
                case .earnCredits:
                    CustomAlertView(
                        title: "Acquire Search Credits",
                        message: "View advertisements to earn search credits at no cost. An advertisement will play if available.",
                        primaryButtonTitle: "View Advertisement",
                        primaryAction: {
                            contentVM.handleRewardAd(reward: "credits", rewardAdController: rewardAd)
                            sharedAlertVM.currentAlertType = nil
                        },
                        secondaryButtonTitle: "Purchase",
                        secondaryAction: {
                            activeSheet = .storefront
                            sharedAlertVM.currentAlertType = nil
                        },
                        dismissAction: {
                            sharedAlertVM.currentAlertType = nil
                        }
                    )
                    
                default:
                    CustomAlertView(
                        title: "Error",
                        message: "Something went wrong.",
                        dismissAction: {
                            sharedAlertVM.currentAlertType = nil
                        }
                    )
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowSearchResults"))) { _ in
            if contentVM.showBrewPreview && !contentVM.brewLocations.isEmpty {
                activeSheet = .searchResults
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MapAnnotationTapped"))) { notification in
            if let location = notification.object as? BrewLocation {
                contentVM.selectedBrewLocation = location
                selectedCoffeeShop.coffeeShop = location
                
                // Reorder search results to show tapped location first
                if contentVM.brewLocations.firstIndex(where: { $0.id == location.id }) != nil {
                    let reorderedLocations = contentVM.brewLocations
                    contentVM.brewLocations.removeAll()
                    contentVM.brewLocations.append(location)
                    contentVM.brewLocations.append(contentsOf: reorderedLocations.filter { $0.id != location.id })
                }
                
                // Show search results sheet with tapped location at top
                activeSheet = .searchResults
            }
        }
        .onAppear {
            if locationManager.isLocationAccessGranted {
                centeredOnUser = true
            }
        }
    }
}

struct BottomControlPanel: View {
    @Binding var isCoffeeSelected: Bool
    let locationManager: LocationManager
    @Binding var centeredOnUser: Bool
    @Binding var showLocationAccessAlert: Bool
    @Binding var activeSheet: ActiveSheet?
    let userVM: UserViewModel
    let contentVM: ContentViewModel
    let visibleRegionCenter: CLLocationCoordinate2D?
    @EnvironmentObject var sharedAlertVM: SharedAlertViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    print("Search button tapped. User credits: \(userVM.user.credits)")
                    if userVM.user.credits > 0 {
                        if isCoffeeSelected {
                            print("Searching for coffee shops")
                            contentVM.fetchBrewies(locationManager: locationManager, visibleRegionCenter: visibleRegionCenter, brewType: "coffee", term: "Local Coffee")
                        } else {
                            print("Searching for breweries")
                            contentVM.fetchBrewies(locationManager: locationManager, visibleRegionCenter: visibleRegionCenter, brewType: "breweries", term: "Local Brewery")
                        }
                    } else {
                        print("Insufficient credits, showing alert")
                        print("Current alert type before: \(String(describing: sharedAlertVM.currentAlertType))")
                        sharedAlertVM.currentAlertType = .insufficientCredits
                        print("Current alert type after: \(String(describing: sharedAlertVM.currentAlertType))")
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.blue, in: Circle())
                }
                
                Toggle(isOn: $isCoffeeSelected) {
                    HStack(spacing: 8) {
                        Image(systemName: isCoffeeSelected ? "cup.and.saucer.fill" : "wineglass.fill")
                        Text(isCoffeeSelected ? "Coffee" : "Breweries")
                            .fontWeight(.medium)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25))
                
                Button(action: {
                    activeSheet = .filter
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 50, height: 50)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
    }
}

struct UserProfileSheetView: View {
    let userVM: UserViewModel
    let contentVM: ContentViewModel
    @State private var localActiveSheet: ActiveSheet?
    
    var body: some View {
        UserProfileView(userViewModel: userVM, contentViewModel: contentVM, activeSheet: $localActiveSheet)
            .sheet(item: $localActiveSheet) { sheet in
                switch sheet {
                case .storefront:
                    StorefrontView()
                default:
                    EmptyView()
                }
            }
    }
}
