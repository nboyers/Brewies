//
//  FiltersView.swift
//  Brewies
//
//  Created by Noah Boyers on 6/23/23.
//
import SwiftUI
import MapKit

class YelpSearchParams: ObservableObject {
    // Actual state
    @Published var radiusInMeters: Int = 5000 // start with 5 miles in meters
    @Published var radiusUnit: String = "mi" // Default unit is miles now
    @Published var businessType: String = "coffee shop"
    @Published var sortBy: String = "distance"
    @Published var price: [String] = []
    @Published var priceForAPI: [Int] = []
    func resetFilters() {
        radiusInMeters = 5000
        radiusUnit = "mi"
        businessType = "coffee shop"
        sortBy = "distance"
        price = []
        priceForAPI = []
    }
}


struct FiltersView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var yelpParams: YelpSearchParams
    @EnvironmentObject var userVM: UserViewModel
    @ObservedObject var contentVM: ContentViewModel
    @EnvironmentObject var sharedAlertVM: SharedAlertViewModel
    @ObservedObject var storeKit = StoreKitManager()
    
    @State private var activeSheet: ActiveSheet?
    @State private var applyChangesCount: Int = 0
    
    @State private var showAlert = false
    @State private var showSubscriptionsView = false
    
    @State private var selectedSort: String = ""
    @State private var selectedOption: Int = 0
    @State private var radiusOptionsInMeters = [8047, 16093, 24140, 32186]
    @State private var selectedBrew = ""
    @State private var initialState: [String: Any] = [:]
    var visibleRegionCenter: CLLocationCoordinate2D?
    
    let sortOptions = ["Recommended", "Distance", "Rating", "Review"]
    let apiSortOptions: [String: String] = ["Recommended": "best_match", "Distance": "distance", "Rating": "rating", "Review": "review_count"]
    let priceOptions = ["$", "$$", "$$$", "$$$$"]
    let brewType = ["Coffee Shops", "Breweries"]
    
    private func changesCount() -> Int {
        var changesCount = 0
        if let initialPrice = initialState["price"] as? [Int] {
            let addedPrice = yelpParams.priceForAPI.filter { !initialPrice.contains($0) }
            let removedPrice = initialPrice.filter { !yelpParams.priceForAPI.contains($0) }
            changesCount += addedPrice.count + removedPrice.count
        }
        if initialState["sortBy"] as? String != yelpParams.sortBy { changesCount += 1 }
        if initialState["radiusInMeters"] as? Int != yelpParams.radiusInMeters { changesCount += 1 }
        if initialState["businessType"] as? String != yelpParams.businessType {changesCount += 1 }
        return changesCount
    }
    
    private func updateInitialState() {
        initialState["radiusInMeters"] = yelpParams.radiusInMeters
        initialState["radiusUnit"] = yelpParams.radiusUnit
        initialState["businessType"] = yelpParams.businessType
        initialState["sortBy"] = yelpParams.sortBy
        initialState["price"] = yelpParams.priceForAPI // Note: Using priceForAPI instead of price
    }
    
    
    private func priceButtonAction(price: String) {
        if let index = yelpParams.price.firstIndex(of: price) {
            // If price is already selected, remove it from both the price arrays
            yelpParams.price.remove(at: index)
            yelpParams.priceForAPI.remove(at: index)
        } else {
            // If price is not selected, add it to both the price arrays
            yelpParams.price.append(price)
            yelpParams.priceForAPI.append(price.count)
        }
        // Reflect changes in initialState
        updateInitialState()
    }
    
    
    
    
    var body: some View {
        VStack(alignment: .leading) {
            //MARK: HEADERS
            Group {
                HStack {
                    Button(action: {
                        sharedAlertVM.currentAlertType = nil
                        self.presentationMode.wrappedValue.dismiss()
                        // Reset the Settings Applied
                        yelpParams.resetFilters()
                        
                        // Also reset the UI
                        selectedSort = ""
                        selectedBrew = ""
                        // Update the initial state to match the reset parameters
                        updateInitialState()
                    }) {
                        Text("Close")
                            .font(.system(size: 20, weight: .medium))
                            .padding()
                            .font(.title3)
                            .foregroundColor(.teal)
                    }
                    
                    Spacer()
                    Text("Filters")
                        .bold()
                        .font(.title3)
                    Spacer()
                    Button(action: {
                        if !userVM.user.isSubscribed {
                            sharedAlertVM.currentAlertType = .notSubscribed
                        } else {
                            // Reset the Settings Applied
                            yelpParams.resetFilters()
                            // Also reset the UI
                            selectedSort = ""
                            selectedBrew = ""
                            
                            // Update the initial state to match the reset parameters
                            updateInitialState()
                        }
                    }) {
                        Text("Reset")
                            .font(.system(size: 20, weight: .medium))
                            .padding()
                            .font(.title3)
                            .foregroundColor(.teal)
                    }
                }
            }
            
            Divider()
            
            ScrollView {
                //MARK: Search Radius
                Group {
                    Text("Price")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    HStack(alignment: .center, spacing: 10) {
                        Spacer()
                        ForEach(priceOptions, id: \.self) { price in
                            Button(action: {
                                if !userVM.user.isSubscribed {
                                    sharedAlertVM.currentAlertType = .notSubscribed
                                } else {
                                    priceButtonAction(price: price)
                                }
                            }){
                                Text(price)
                                    .frame(width: 80, height: 35)
                                    .background(yelpParams.price.contains(price) ? Color.blue : Color.clear)
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(colorScheme == .dark ? Color.white : Color.black, lineWidth: yelpParams.price.contains(price) ? 0 : 1) // Show border when the button is clear
                                    )
                                    .font(.body)
                                
                            }
                            
                        }.padding(.vertical)
                        Spacer()
                    }
                }
                
                
                Divider()
                
                //MARK: SORT
                Group {
                    Text("Sort")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    ForEach(sortOptions, id: \.self) { sortOption in
                        HStack {
                            Text(sortOption)
                                .font(.body)
                            Spacer()
                            Button(action: {
                                if !userVM.user.isSubscribed {
                                    sharedAlertVM.currentAlertType = .notSubscribed
                                } else {
                                    selectedSort = sortOption
                                    yelpParams.sortBy = apiSortOptions[selectedSort] ?? ""
                                }
                            }) {
                                Circle()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(selectedSort == sortOption ? .blue : .clear)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(colorScheme == .dark ? Color.white : Color.black, lineWidth: selectedSort == sortOption ? 0 : 1)
                                    )
                            }
                            
                        }
                        .padding(.horizontal)
                    }
                }
                
                
                
                
                
                Divider()
                
                //MARK: SEARCH RADIUS
                Group {
                    Text("Search Radius")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    Picker("Search Radius", selection: $yelpParams.radiusInMeters) {
                        ForEach(radiusOptionsInMeters, id: \.self) { unit in
                            Text("\(yelpParams.radiusUnit == "km" ? Double(unit)/1000.0 : Double(unit)/1609.34, specifier: "%.2f") \(yelpParams.radiusUnit)").tag(unit)
                            
                        }
                    }
                    
                    .padding(.horizontal)
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle(isOn: Binding<Bool>(
                        get: { yelpParams.radiusUnit == "km" },
                        set: { newValue in
                            yelpParams.radiusUnit = newValue ? "km" : "mi"
                            // Change the radius options when the unit changes
                        }
                    ), label: { Text(yelpParams.radiusUnit == "km" ? "Metric" : "Imperial") })
                    .padding(.horizontal)
                }
                .disabled(!userVM.user.isSubscribed)
                
                Divider()
                
                Button(action: {
                    // Trigger the presentation of the SubscriptionsView
                    showSubscriptionsView = true
                }) {
                    Text("Store")
                        .fontWeight(.semibold)
                        .font(.system(size: 16)) // Smaller font size for a more refined look
                        .padding(10) // Adjust padding to suit the new size
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.init(hex: "#303c38").opacity(0.6), Color.init(hex: "#303c38").opacity(0.7)]), startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(15) // Matching corner radius with the "Store" button
                        .padding(.horizontal, 20) // Adjust horizontal padding to balance the button within the layout
                        .shadow(color: .red.opacity(0.3), radius: 3, x: 0, y: 2) // Softer shadow for a cleaner look
                    
                }
//                .padding(.bottom, 10) // Add some space below the button, if needed


                .sheet(isPresented: $showSubscriptionsView) {
                   StorefrontView()
                }
                
//                Spacer()
                
            }
        }
        // MARK: NO SUBSCRIPTION ALERT
        .overlay {
            Group {
                if sharedAlertVM.currentAlertType == .notSubscribed {
                    CustomAlertView(
                        title: "Subscription Required",
                        message: "You need to be subscribed to use the filters view.",
                        primaryButtonTitle: "Go to Store",
                        primaryAction: {
                            showAlert = true
                            sharedAlertVM.currentAlertType = nil
                            
                        },
                        dismissAction: {
                            // Add your action for the dismiss button here
                            sharedAlertVM.currentAlertType = nil
                            
                        }
                    )
                    .frame(width: 300, height: 200)  // Adjust the frame as needed
                    .background(VisualEffectBlur(blurStyle: .systemMaterial))  // Optional: Add a blur effect
                    .cornerRadius(20)
                    .shadow(radius: 20)
                }
                
            }
        }
        
        .onAppear {
            initialState["radiusInMeters"] = yelpParams.radiusInMeters
            initialState["radiusUnit"] = yelpParams.radiusUnit
            initialState["businessType"] = yelpParams.businessType
            initialState["sortBy"] = yelpParams.sortBy
            initialState["price"] = yelpParams.price
        }
        
        HStack(alignment: .center) {
            Spacer()
                .frame(width: 25)
            
//            GeometryReader { geo in
                Button(action: {
                    if !userVM.user.isSubscribed {
                        sharedAlertVM.currentAlertType = .notSubscribed
                    } else {
                        updateInitialState()
                        // Close the view
                        sharedAlertVM.currentAlertType = nil
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    let changesCount = self.changesCount()
                    Text("Apply\(changesCount > 0 ? " (\(changesCount))" : "")")
                    
                        .fontWeight(.semibold)
                        .font(.system(size: 16)) // Smaller font size
                        .padding(15) // Reduced padding
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.5), Color.red.opacity(0.7)]), startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(15) // Smaller corner radius
                        .padding(.horizontal, 20) // Adjust horizontal padding as needed
                        .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 2) // Less aggressive shadow
                }
                .padding(.bottom, 10) // Add space below the button if needed
                .cornerRadius(15)
//            }
            Spacer()
                .frame(width: 25)
        }
        
        .frame(maxHeight: 75)
        .sheet(isPresented: $showAlert) {
            StorefrontView()
        }
    }
}
