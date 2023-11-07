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
import AppTrackingTransparency

struct ContentView: View {
    @ObservedObject var storeKit = StoreKitManager()
    @ObservedObject var locationManager = LocationManager()
    @StateObject var sharedAlertVM = SharedAlertViewModel()
    
    private var rewardAd = RewardAdController()
    let signInCoordinator = SignInWithAppleCoordinator()
    
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme (dark or light mode)
    @EnvironmentObject var sharedVM: SharedViewModel
    
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var yelpParams: YelpSearchParams
    @EnvironmentObject var contentVM: ContentViewModel
    
    @EnvironmentObject var selectedCoffeeShop: SelectedCoffeeShop
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var visibleRegionCenter: CLLocationCoordinate2D?
    @State private var activeSheet: ActiveSheet?
    
    @State private var howInstructions = false
    @State private var swirlColors: (UIColor, UIColor)? = nil
    
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
    @State private var currentStreakColor: Color = .cyan
    
    private func getRandomColor() -> UIColor {
        return UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )
    }
    
    private func updateStreakColor() {
        if userVM.user.streakCount % 7 == 0 && userVM.user.streakCount != 0 {
            let randomColor1 = getRandomColor()
            let randomColor2 = userVM.user.streakCount >= 365 ? getRandomColor() : randomColor1
            // Save the colors
            let colorsData = try? NSKeyedArchiver.archivedData(withRootObject: [randomColor1, randomColor2], requiringSecureCoding: false)
            UserDefaults.standard.set(colorsData, forKey: "streakColors")
        } else if userVM.user.streakCount == 0 {
            currentStreakColor = .cyan
            UserDefaults.standard.removeObject(forKey: "streakColors")
        }    else if let colorsData = UserDefaults.standard.data(forKey: "streakColors"),
                     let savedColors = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: colorsData) as? [UIColor],
                     savedColors.count == 2 {
            self.swirlColors = (savedColors[0], savedColors[1])
        }
    }
    
    
    
    
    
    
    
    private func shouldAllowAd() -> String {
        if !userVM.user.isLoggedIn {
            return "No_Login"
        }
        // Check if it's been 28 hours since the last check-in.
        guard let lastDate = userVM.user.streakViewedDate else {
            // It's the user's first time, or it hasn't been 28hrs
            let hasCheckedInBefore = UserDefaults.standard.bool(forKey: "hasCheckedInBefore")
            if hasCheckedInBefore {
                return "Too_Soon"
            } else {
                // Set the flag to true for future reference
                UserDefaults.standard.set(true, forKey: "hasCheckedInBefore")
                return "Reward_User"
            }
        }
        
        let elapsedHours = Calendar.current.dateComponents([.hour], from: lastDate, to: Date()).hour ?? 0
        
        if elapsedHours <= 28 && elapsedHours >= 24 && userVM.user.isLoggedIn {
            // It's been less than 28 hours, prompt to watch ad
            return "Reward_User"
        }
        // It's been 24 hours or less, too soon to earn another streak point
        return "Too_Soon"
    }
    
    
    
    @FocusState var isInputActive: Bool
    
    let DISTANCE = CLLocationDistance(2500)
    init() {}
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
                                    Image(systemName: "location.circle.fill")
                                        .resizable()
                                        .clipShape(Circle())
                                        .aspectRatio(contentMode: .fit) // Maintain the aspect ratio of your image
                                        .foregroundColor(.white) // Set the arrow color to blue
                                        .frame(width: 50, height: 50) // Set the frame size for your image
                                        .background(Circle().fill(Color.blue)) // Apply a white background in a circle shape
                                    // Clip the image with its background to a circle
                                    
                                    
                                    
                                }
                                .offset(CGSize(width: geo.size.width/10 - 20, height: geo.size.width*1.55))
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
                            
                            
                            TextField("Search the Area", text: $searchQuery, onEditingChanged: { isEditing in
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
                        if !storeKit.storeStatus.isAdRemovalPurchased && !userVM.user.isSubscribed {
                            AdBannerView()
                                .frame(width: 320, height: 50)
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
                            // .font(geometry.size.width > 320 ? .body : .footnote)
                                .font(.system(size: geo.size.width <= 375 ? 17 : 20, weight: .bold))
                            //                                .padding(.horizontal, geo.size.width > 320 ? 20 : 10)
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
                    
                    
                    Button(action: {
                        
                        switch shouldAllowAd() {
                        case "No_Login": // User is not logged in
                            sharedAlertVM.currentAlertType = .notLoggedIn
                            
                        case "Too_Soon": // User comes before 24hrs
                            sharedAlertVM.currentAlertType = .tooSoon
                            
                            
                        case "Reward_User":  // User is logged in & over 24hrs since last checkin
                            sharedAlertVM.currentAlertType = .streakCount
                            
                        default: // Show them how to use the System
                            sharedAlertVM.currentAlertType = .showInstructions
                            
                        }
                    }) {
                        Text("\(userVM.user.streakCount)")
                            .font(.callout)
                            .bold()
                            .padding()
                            .background(Circle().fill(currentStreakColor))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                    }
                    .offset(CGSize(width: geo.size.width*0.80, height: geo.size.height/13))
                    
                    
                }
                
                if  sharedAlertVM.currentAlertType != nil {
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
                                    ATTrackingManager.requestTrackingAuthorization { [self] status in
                                        switch status {
                                        case .authorized:
                                            // Here, you can continue with ad loading as the user has given permission
                                            self.contentVM.handleRewardAd(reward: "favorites")
                                        case .denied, .restricted:
                                            // Handle the case where permission is denied
                                            self.contentVM.handleRewardAd(reward: "favorites")
                                            break
                                        case .notDetermined:
                                            // The user has not decided on permission
                                            self.contentVM.handleRewardAd(reward: "favorites")
                                            break
                                        @unknown default:
                                            break
                                        }
                                    }
                                }
                                self.contentVM.handleRewardAd(reward: "favorites")
                                sharedAlertVM.currentAlertType = nil
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
                                    ATTrackingManager.requestTrackingAuthorization { [self] status in
                                        switch status {
                                        case .authorized:
                                            // Here, you can continue with ad loading as the user has given permission
                                            self.contentVM.handleRewardAd(reward: "credits")
                                        case .denied, .restricted:
                                            // Handle the case where permission is denied
                                            self.contentVM.handleRewardAd(reward: "credits")
                                            break
                                        case .notDetermined:
                                            // The user has not decided on permission
                                            self.contentVM.handleRewardAd(reward: "credits")
                                            break
                                        @unknown default:
                                            break
                                        }
                                    }
                                }
                                self.contentVM.handleRewardAd(reward: "credits")
                                sharedAlertVM.currentAlertType = nil
                            },
                            secondaryButtonTitle: "Go to Store",
                            secondaryAction: {
                                activeSheet = .storefront
                                sharedAlertVM.currentAlertType = nil
                            },
                            dismissAction: {
                                sharedAlertVM.currentAlertType = nil
                            })
                        
                    case .streakCount:
                        CustomAlertView(
                            title: "Watch an Ad",
                            message: "Watch the ad to increase your streak count",
                            primaryButtonTitle: "Watch Ad",
                            primaryAction: {
                                self.contentVM.handleRewardAd(reward: "check_in")
                                sharedAlertVM.currentAlertType = nil
                            },
                            dismissAction: {
                                sharedAlertVM.currentAlertType = nil
                            })
                        
                    case .notLoggedIn:
                        CustomAlertView(
                            title: "Sign In Required",
                            message: "Please sign in to use Daily Check In",
                            primaryButtonTitle: "Sign In",
                            primaryAction: {
                                signInCoordinator.startSignInWithAppleFlow()
                                sharedAlertVM.currentAlertType = nil
                            },
                            secondaryButtonTitle: "Explain",
                            secondaryAction: {
                                howInstructions = true
                            },
                            dismissAction: {
                                sharedAlertVM.currentAlertType = nil
                            })
                        
                    case .tooSoon:
                        CustomAlertView(
                            title: "Not Yet",
                            message: "You can re-check in at \(userVM.timeLeft())",
                            primaryButtonTitle: "Reward",
                            primaryAction: {
                                if userVM.isWeeklyRewardAvailable() {
                                    sharedAlertVM.currentAlertType = .streakReward
                                } else {
                                    sharedAlertVM.currentAlertType = .showNotEnoughStreakAlert
                                }
                            },
                            secondaryButtonTitle: "Explain",
                            secondaryAction: {
                                howInstructions = true
                            },
                            dismissAction: {
                                sharedAlertVM.currentAlertType = nil
                            }
                        )
                        
                    case .streakReward:
                        CustomAlertView(
                            title: "Choose your Reward!",
                            message: "Thank you for using Brewies",
                            primaryButtonTitle: "Discover \nCredits",
                            primaryAction: {
                                userVM.claimDiscoverCreditsReward()
                                sharedAlertVM.currentAlertType = nil
                            },
                            secondaryButtonTitle: "Favorite \nSlot",
                            secondaryAction: {
                                userVM.claimFavoriteSlotsReward()
                                sharedAlertVM.currentAlertType = nil
                            },
                            dismissAction: {
                                sharedAlertVM.currentAlertType = .streakReward // Makes sure user cannot be scammed
                            }
                        )
                    case .showNotEnoughStreakAlert:
                        CustomAlertView(
                            title: "Not Enough Streak",
                            message: "You don't have enough streak amount to claim a reward. Keep checking in daily to increase your streak count!",
                            primaryButtonTitle: "OK",
                            primaryAction: {
                                sharedAlertVM.currentAlertType = nil
                            },
                            dismissAction: {
                                sharedAlertVM.currentAlertType = nil
                            }
                        )
                        
                    default:
                        CustomAlertView(
                            title: "Mr. Dev Man Broke Something",
                            message: "Existence is Pain",
                            dismissAction: {
                                sharedAlertVM.currentAlertType = nil
                            }
                        )
                    }
                }
            }
            
            .sheet(isPresented: $howInstructions) {
                InstructionsView()
            }
            
            
            //MARK: User Profile
            .sheet(item: $activeSheet) { sheet in
                
                switch sheet {
                case .filter:
                    FiltersView(yelpParams: yelpParams, contentVM: contentVM, visibleRegionCenter: visibleRegionCenter)
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
                    if let coffeeShop = selectedCoffeeShop.coffeeShop { BrewDetailView(coffeeShop: coffeeShop) }
                    
                    
                case .shareApp:
                    ShareSheet(activityItems: ["Share Brewies", URL(string: "https://apps.apple.com/us/app/brewies/id6450864433")!])
                        .presentationDetents([.medium])
                    
                }
            }
            .alert(isPresented: $showLocationAccessAlert) {
                Alert(
                    title: Text("Location Access Required"),
                    message: Text("To give local recommendations, Brewies needs access to your location. You can enable location services for Brewies in the Settings app."),
                    primaryButton: .default(Text("Settings"), action: {
                        // This line opens the Settings app
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
                
                return
            }
            guard let placemark = placemarks?.first, let location = placemark.location else {
                
                return
            }
            
            DispatchQueue.main.async {
                self.searchedLocation = location.coordinate
            }
        }
    }
}

