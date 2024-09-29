//
//  FiltersView.swift
//  Brewies
//
//  Created by Noah Boyers on 6/23/23.
//
import SwiftUI
import MapKit


struct FiltersView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var googlePlacesParams: GooglePlacesSearchParams
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
    @State private var radiusOptionsInMeters = [8047, 16093, 24140, 32186] // 5, 10, 15, 20 miles in meters
    @State private var selectedBrew = ""
    @State private var initialState: [String: Any] = [:]
    var visibleRegionCenter: CLLocationCoordinate2D?
    
    let sortOptions = ["Prominence", "Distance"]
    let apiSortOptions: [String: String] = ["Prominence": "prominence", "Distance": "distance"]
    let priceOptions = ["$", "$$", "$$$", "$$$$"]
    let brewTypes = ["Cafes", "Bars", "Restaurants"]
    
    private func changesCount() -> Int {
        var changesCount = 0
        if let initialPrice = initialState["priceLevels"] as? [Int] {
            let addedPrice = googlePlacesParams.priceLevels.filter { !initialPrice.contains($0) }
            let removedPrice = initialPrice.filter { !googlePlacesParams.priceLevels.contains($0) }
            changesCount += addedPrice.count + removedPrice.count
        }
        if initialState["sortBy"] as? String != googlePlacesParams.sortBy { changesCount += 1 }
        if initialState["radiusInMeters"] as? Int != googlePlacesParams.radiusInMeters { changesCount += 1 }
        if initialState["businessType"] as? String != googlePlacesParams.businessType { changesCount += 1 }
        return changesCount
    }
    
    private func updateInitialState() {
        initialState["radiusInMeters"] = googlePlacesParams.radiusInMeters
        initialState["radiusUnit"] = googlePlacesParams.radiusUnit
        initialState["businessType"] = googlePlacesParams.businessType
        initialState["sortBy"] = googlePlacesParams.sortBy
        initialState["priceLevels"] = googlePlacesParams.priceLevels
    }
    
    private func priceButtonAction(price: String) {
        let priceIndex = priceOptions.firstIndex(of: price) ?? 0
        if let index = googlePlacesParams.priceLevels.firstIndex(of: priceIndex) {
            // If price is already selected, remove it
            googlePlacesParams.priceLevels.remove(at: index)
        } else {
            // If price is not selected, add it
            googlePlacesParams.priceLevels.append(priceIndex)
        }
        updateInitialState()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // MARK: Headers
            Group {
                HStack {
                    Button(action: {
                        sharedAlertVM.currentAlertType = nil
                        self.presentationMode.wrappedValue.dismiss()
                        // Reset the settings
                        googlePlacesParams.resetFilters()
                        selectedSort = ""
                        selectedBrew = ""
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
                            googlePlacesParams.resetFilters()
                            selectedSort = ""
                            selectedBrew = ""
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
                // MARK: Price Filter
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
                                    .background(googlePlacesParams.priceLevels.contains(price.count - 1) ? Color.blue : Color.clear)
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(colorScheme == .dark ? Color.white : Color.black, lineWidth: googlePlacesParams.priceLevels.contains(price.count - 1) ? 0 : 1)
                                    )
                                    .font(.body)
                            }
                        }.padding(.vertical)
                        Spacer()
                    }
                }
                
                Divider()
                
                // MARK: Sort Options
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
                                    googlePlacesParams.sortBy = apiSortOptions[selectedSort] ?? ""
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
                
                // MARK: Search Radius
                Group {
                    Text("Search Radius")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    Picker("Search Radius", selection: $googlePlacesParams.radiusInMeters) {
                        ForEach(radiusOptionsInMeters, id: \.self) { unit in
                            Text("\(googlePlacesParams.radiusUnit == "km" ? Double(unit) / 1000.0 : Double(unit) / 1609.34, specifier: "%.2f") \(googlePlacesParams.radiusUnit)").tag(unit)
                        }
                    }
                    .padding(.horizontal)
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle(isOn: Binding<Bool>(
                        get: { googlePlacesParams.radiusUnit == "km" },
                        set: { newValue in
                            googlePlacesParams.radiusUnit = newValue ? "km" : "mi"
                        }
                    ), label: { Text(googlePlacesParams.radiusUnit == "km" ? "Metric" : "Imperial") })
                    .padding(.horizontal)
                }
                .disabled(!userVM.user.isSubscribed)
                
                Divider()
                
                // MARK: Apply Changes
                HStack(alignment: .center) {
                    Spacer()
                        .frame(width: 25)
                    
                    Button(action: {
                        if !userVM.user.isSubscribed {
                            sharedAlertVM.currentAlertType = .notSubscribed
                        } else {
                            updateInitialState()
                            sharedAlertVM.currentAlertType = nil
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        let changesCount = self.changesCount()
                        Text("Apply\(changesCount > 0 ? " (\(changesCount))" : "")")
                            .fontWeight(.semibold)
                            .font(.system(size: 16))
                            .padding(15)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.5), Color.red.opacity(0.7)]), startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .padding(.horizontal, 20)
                            .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    .padding(.bottom, 10)
                    .cornerRadius(15)
                    
                    Spacer()
                        .frame(width: 25)
                }
            }
        }
        .onAppear {
            updateInitialState()
        }
    }
}

