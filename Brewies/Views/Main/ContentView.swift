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
    @StateObject var sharedAlertVM = SharedAlertViewModel()

    let signInCoordinator = SignInWithAppleCoordinator()

    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var sharedVM: SharedViewModel
    @EnvironmentObject var rewardAd: RewardAdController
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var contentVM: ContentViewModel
    @EnvironmentObject var selectedCoffeeShop: SelectedCoffeeShop
    @EnvironmentObject var locationManager: LocationManager
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

    var body: some View {
        TabView {
            ZStack {
                ZStack {
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
                               centeredOnUser = true // Center the map on user when permission is granted
                           }
                       }


                    // User Location Button
                    if showUserLocationButton {
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
                }

                // Bottom Sheet
                .bottomSheet(bottomSheetPosition: $sharedVM.bottomSheetPosition, switchablePositions: [
                    .relativeBottom(0.20),  // Bottom position
                    .relative(0.70),        // Mid swipe
                    .relativeTop(0.80)      // Top full swipe
                ], headerContent: {
                    HStack(spacing: 20) {
                        Spacer()
                        
                        // Filter Button
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

                        // Toggle Coffee/Wine Button
                        Button(action: {
                            isCoffeeSelected.toggle()
                        }) {
                            Image(systemName: isCoffeeSelected ? "cup.and.saucer.fill" : "wineglass.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(isCoffeeSelected ? Color(hex: "#504b3a") : Color(hex: "#72195a"))
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .gray.opacity(0.5), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Search Button
                        Button(action: {
                            if userVM.user.credits > 0 {
                                if isCoffeeSelected {
                                    contentVM.fetchBrewies(locationManager: locationManager, visibleRegionCenter: visibleRegionCenter, brewType: "coffee", term: "Coffee")
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
                                .background(isCoffeeSelected ? Color(hex: "#504b3a") : Color(hex: "#72195a"))
                                .cornerRadius(25)
                                .shadow(color: .gray.opacity(0.5), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()

                        // User Profile Button
                        Button(action: {
                            if userVM.user.isLoggedIn {
                                activeSheet = .userProfile
                            } else {
                                activeSheet = .signUpWithApple
                            }
                        }) {
                            if !userVM.user.isLoggedIn {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(Color.accentColor)
                                    .clipShape(Circle())
                            } else {
                                Text(String(userVM.user.firstName.prefix(1)))
                                    .foregroundColor(.white)
                                    .font(.system(size: 30, weight: .bold))
                                    .frame(width: 30, height: 30)
                                    .background(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "#afece7"),
                                                Color(hex: "#8ba6a9"),
                                                Color(hex: "#75704e"),
                                                Color(hex: "#987284"),
                                                Color(hex: "#f4ebbe")
                                            ]),
                                            center: .center,
                                            startRadius: 5,
                                            endRadius: 70
                                        )
                                    )
                                    .clipShape(Circle())
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()
                    }
                    .padding(.vertical)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 10)
                    .padding(.horizontal)
                }, mainContent: {
                    Divider()
                    ScrollView {
                        if contentVM.selectedBrewLocation != nil && contentVM.showBrewPreview {
                            HStack {
                                GeometryReader { geo in
                                    Text("\(contentVM.brewLocations.count) Brews In Map")
                                        .padding(.horizontal, geo.size.width * 0.07)
                                }
                                Spacer()
                            }

                            BrewPreviewList(coffeeShops: $contentVM.brewLocations,
                                            selectedCoffeeShop: $contentVM.selectedBrewLocation,
                                            showBrewPreview: $contentVM.showBrewPreview,
                                            activeSheet: $activeSheet)
                        }
                        if !storeKit.storeStatus.isAdRemovalPurchased && !userVM.user.isSubscribed {
                            AdBannerView()
                                .frame(width: 320, height: 50)
                        }
                    }
                })

                .enableAppleScrollBehavior()
                .enableBackgroundBlur()
                .backgroundBlurMaterial(.systemDark)

                GeometryReader { geo in
                    VStack {
                        Button(action: {
                            DispatchQueue.global(qos: .background).async {
                                rewardAd.loadRewardedAd()
                            }
                            sharedAlertVM.currentAlertType = .earnCredits
                        }) {
                            HStack {
                                Text("Discover Credits: \(userVM.user.credits)")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "#afece7").opacity(0.85)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(15)
                                    .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.cyan.opacity(0.8), lineWidth: 1)
                                    )
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding()
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .offset(CGSize(width: geo.size.width * 0.02 - 5, height: geo.size.width / 7 - 20))
                }

                if sharedAlertVM.currentAlertType != nil {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)

                    switch sharedAlertVM.currentAlertType {
                    case .maxFavoritesReached:
                        CustomAlertView(
                            title: "Maximum Favorites Reached",
                            message: "Watch an ad to unlock more favorite slots or go to the store.",
                            primaryButtonTitle: "Go to Store",
                            primaryAction: {
                                activeSheet = .storefront
                                sharedAlertVM.currentAlertType = nil
                            },
                            secondaryButtonTitle: "Watch Ad",
                            secondaryAction: {
                                if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                                    ATTrackingManager.requestTrackingAuthorization { status in
                                        contentVM.handleRewardAd(reward: "favorites")
                                    }
                                } else {
                                    contentVM.handleRewardAd(reward: "favorites")
                                    sharedAlertVM.currentAlertType = nil
                                }
                            },
                            dismissAction: {
                                sharedAlertVM.currentAlertType = nil
                            })

                    case .insufficientCredits:
                        CustomAlertView(
                            title: "Insufficient Credits",
                            message: "Watch an ad to get a discover credit or go to the store.",
                            primaryButtonTitle: "Watch Ad",
                            primaryAction: {
                                if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                                    ATTrackingManager.requestTrackingAuthorization { status in
                                        contentVM.handleRewardAd(reward: "credits")
                                    }
                                } else {
                                    contentVM.handleRewardAd(reward: "credits")
                                    sharedAlertVM.currentAlertType = nil
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
                                contentVM.handleRewardAd(reward: "credits")
                                sharedAlertVM.currentAlertType = nil
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
                    FiltersView(googlePlacesParams: GooglePlacesSearchParams(), contentVM: contentVM, visibleRegionCenter: visibleRegionCenter)
                        .environmentObject(userVM)
                        .environmentObject(sharedAlertVM)


                case .userProfile:
                    UserProfileView(userViewModel: userVM, contentViewModel: contentVM, activeSheet: $activeSheet)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.medium])

                case .signUpWithApple:
                    if userVM.user.isLoggedIn {
                        UserProfileView(userViewModel: userVM, contentViewModel: contentVM, activeSheet: $activeSheet)
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
