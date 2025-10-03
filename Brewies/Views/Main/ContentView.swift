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
    @EnvironmentObject var storeKit: StoreKitManager
    @StateObject var sharedAlertVM = SharedAlertViewModel()

    let signInCoordinator = SignInWithAppleCoordinator()

    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var sharedVM: SharedViewModel
    @EnvironmentObject var rewardAd: RewardAdController
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var contentVM: ContentViewModel
    @EnvironmentObject var selectedCoffeeShop: SelectedCoffeeShop
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var attManager: ATTManager
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State private var visibleRegionCenter: CLLocationCoordinate2D?
    @State private var activeSheet: ActiveSheet?

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
    @State private var settingsView = false
    @State private var isCoffeeSelected = true

    @FocusState var isInputActive: Bool

    let DISTANCE = CLLocationDistance(2500)
    
    private var mapView: some View {
        MapView(
            locationManager: locationManager,
            coffeeShops: $contentVM.brewLocations,
            selectedCoffeeShop: $contentVM.selectedBrewLocation,
            centeredOnUser: $centeredOnUser,
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
        .onReceive(locationManager.$isLocationAccessGranted) { isGranted in
            if isGranted {
                centeredOnUser = true
            }
        }
    }

    private var userLocationButton: some View {
        GeometryReader { geo in
            if !locationManager.isLocationAccessGranted {
                Button(action: {
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
                Button(action: {
                    centeredOnUser = true
                }) {
                    Image(systemName: "location.circle.fill")
                        .resizable()
                        .clipShape(Circle())
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.blue))
                }
                .offset(CGSize(width: geo.size.width/10 - 20, height: geo.size.width*1.55))
            }
        }
    }
    
    private var mapWithLocationButton: some View {
        ZStack {
            mapView
            if showUserLocationButton {
                userLocationButton
            }
        }
    }
    
    private var filterButton: some View {
        Button(action: {
            activeSheet = .filter
        }) {
            Image(systemName: "ellipsis.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.white)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: .gray.opacity(0.5), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var coffeeWineToggleButton: some View {
        Button(action: {
            isCoffeeSelected.toggle()
        }) {
            Image(systemName: isCoffeeSelected ? "cup.and.saucer.fill" : "wineglass.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .foregroundColor(isCoffeeSelected ? Color("#504b3a") : Color("#72195a"))
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .gray.opacity(0.5), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var searchButton: some View {
        Button(action: {
            if userVM.user.credits > 0 {
                if isCoffeeSelected {
                    contentVM.fetchBrewies(locationManager: locationManager, visibleRegionCenter: visibleRegionCenter, brewType: "cafe", term: "Coffee")
                } else {
                    contentVM.fetchBrewies(locationManager: locationManager, visibleRegionCenter: visibleRegionCenter, brewType: "breweries", term: "Brewery")
                }
            } else {
                sharedAlertVM.currentAlertType = .insufficientCredits
            }
        }) {
            Text("Search")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 125, height: 50)
                .background(isCoffeeSelected ? Color("#504b3a") : Color("#72195a"))
                .cornerRadius(25)
                .shadow(color: .gray.opacity(0.5), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var bottomSheetHeader: some View {
        VStack(spacing: 0) {
            // Credits and filter row
            HStack {
                // Credits display
                Button(action: {
                    activeSheet = .storefront
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 13, weight: .medium))
                        Text("\(userVM.user.credits)")
                            .font(.system(size: 15, weight: .semibold))
                        Text("credits")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.tertiarySystemFill))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .simultaneousGesture(TapGesture())
                
                Spacer()
                
                // Filter button
                Button(action: {
                    activeSheet = .filter
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color(UIColor.tertiarySystemFill))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .simultaneousGesture(TapGesture())
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 6)
            
            // Coffee/Brewery toggle
            HStack(spacing: 0) {
                Button(action: {
                    isCoffeeSelected = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 13, weight: .medium))
                        Text("Coffee")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(isCoffeeSelected ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isCoffeeSelected ? Color.accentColor : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .simultaneousGesture(TapGesture())
                
                Button(action: {
                    isCoffeeSelected = false
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "wineglass.fill")
                            .font(.system(size: 13, weight: .medium))
                        Text("Breweries")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(!isCoffeeSelected ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(!isCoffeeSelected ? Color.accentColor : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .simultaneousGesture(TapGesture())
            }
            .padding(.horizontal, 2)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            
            // Search button
            Button(action: {
                if userVM.user.credits > 0 {
                    if isCoffeeSelected {
                        contentVM.fetchBrewies(locationManager: locationManager, visibleRegionCenter: visibleRegionCenter, brewType: "cafe", term: "Coffee")
                    } else {
                        contentVM.fetchBrewies(locationManager: locationManager, visibleRegionCenter: visibleRegionCenter, brewType: "breweries", term: "Brewery")
                    }
                } else {
                    sharedAlertVM.currentAlertType = .insufficientCredits
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Search Nearby")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(TapGesture())
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    var body: some View {
        TabView {
            ZStack {
                mapWithLocationButton

                // Bottom Sheet
                .bottomSheet(bottomSheetPosition: $sharedVM.bottomSheetPosition, switchablePositions: [
                    .relativeBottom(0.30),  // Bottom position - shows search button
                    .relative(0.70),        // Mid swipe
                    .relativeTop(0.95)      // Top full swipe
                ], headerContent: {
                    bottomSheetHeader
                }, mainContent: {
                    if contentVM.selectedBrewLocation != nil && contentVM.showBrewPreview {
                        VStack(spacing: 0) {
                            // Results header
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(min(contentVM.brewLocations.count, 10)) Results")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Text("Coffee shops and breweries nearby")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.systemBackground))
                            
                            Divider()
                            
                            // Results list
                            LazyVStack(spacing: 0) {
                                ForEach(Array(contentVM.brewLocations.enumerated().prefix(10)), id: \.element.id) { index, location in
                                    BrewListItem(location: location, photoIndex: index, activeSheet: $activeSheet)
                                        .id("\(location.id)-\(index)")
                                        .onTapGesture {
                                            selectedCoffeeShop.coffeeShop = location
                                            activeSheet = .detailBrew
                                        }
                                }
                                
                                AdBannerView()
                                    .frame(maxWidth: .infinity, maxHeight: 60)
                                    .padding(.top, 16)
                                
                                Color.clear
                                    .frame(height: 100)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 8) {
                                Text("Find Coffee & Breweries")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("Search to discover nearby places")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.systemBackground))
                    }
                })

                .enableAppleScrollBehavior()
                .enableBackgroundBlur()
                .backgroundBlurMaterial(.systemDark)



                if sharedAlertVM.currentAlertType != nil {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)

                    switch sharedAlertVM.currentAlertType {
                    case .insufficientCredits:
                        CustomAlertView(
                            title: "Insufficient Credits",
                            message: "Watch an ad to get a discover credit or go to the store.",
                            primaryButtonTitle: "Watch Ad",
                            primaryAction: {
                                if rewardAd.isAdAvailable() {
                                    Task {
                                        contentVM.handleRewardAd(reward: "credits", rewardAdController: rewardAd)
                                    }
                                    sharedAlertVM.currentAlertType = nil
                                } else {
                                    sharedAlertVM.currentAlertType = .noAdsAvailableAlert
                                }
                            },
                            secondaryButtonTitle: "Go to Store",
                            secondaryAction: {
                                activeSheet = .storefront
                                sharedAlertVM.currentAlertType = nil
                            },
                            dismissAction: {
                                sharedAlertVM.currentAlertType = nil
                            })

                    case .noAdsAvailableAlert:
                        CustomAlertView(
                            title: "No Ad Available",
                            message: "Sorry, there is no ad available to watch right now. Please try again later.",
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
                            title: "Earn Credits",
                            message: "Watch ads to earn credits for free. An Ad will play if one is ready.",
                            primaryButtonTitle: "Earn Credits",
                            primaryAction: {
                                if rewardAd.isAdAvailable() {
                                    Task {
                                        contentVM.handleRewardAd(reward: "credits", rewardAdController: rewardAd)
                                    }
                                    sharedAlertVM.currentAlertType = nil
                                } else {
                                    sharedAlertVM.currentAlertType = .noAdsAvailableAlert
                                }
                            },
                            secondaryButtonTitle: "Store",
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

            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .filter:
                    FiltersView(googlePlacesParams: contentVM.googlePlacesParams, contentVM: contentVM, visibleRegionCenter: visibleRegionCenter)
                        .environmentObject(userVM)
                        .environmentObject(sharedAlertVM)

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
                    EmptyView()
                }
            }
            .sheet(isPresented: $settingsView) {
                SettingsView(activeSheet: $activeSheet)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.medium])
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
            .edgesIgnoringSafeArea(.top)
            .tabItem {
                Image(systemName: "map")
                Text("Map")
            }

            FavoritesView(showPreview: $contentVM.showBrewPreview,
                          activeSheet: $activeSheet)
                .environmentObject(rewardAd)
                .environmentObject(userVM)
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Favorites")
                }
        }

    }
}

