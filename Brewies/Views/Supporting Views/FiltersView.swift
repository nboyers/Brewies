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
    @EnvironmentObject var storeKit: StoreKitManager
    
    @State private var activeSheet: ActiveSheet?
    @State private var applyChangesCount: Int = 0
    @State private var showAlert = false

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
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Price Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Price Range")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 8) {
                                ForEach(priceOptions, id: \.self) { price in
                                    Button(action: {
                                        priceButtonAction(price: price)
                                    }) {
                                        Text(price)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(googlePlacesParams.priceLevels.contains(price.count - 1) ? .white : .primary)
                                            .frame(minWidth: 44, minHeight: 32)
                                            .padding(.horizontal, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(googlePlacesParams.priceLevels.contains(price.count - 1) ? Color.accentColor : Color(UIColor.secondarySystemGroupedBackground))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                Spacer()
                            }
                        }
                        
                        // Sort Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sort By")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 0) {
                                ForEach(Array(sortOptions.enumerated()), id: \.element) { index, sortOption in
                                    Button(action: {
                                        selectedSort = sortOption
                                        googlePlacesParams.sortBy = apiSortOptions[selectedSort] ?? ""
                                    }) {
                                        HStack {
                                            Text(sortOption)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if selectedSort == sortOption {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if index < sortOptions.count - 1 {
                                        Divider()
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                            )
                        }
                        
                        // Radius Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Search Distance")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 16) {
                                Picker("Distance", selection: $googlePlacesParams.radiusInMeters) {
                                    ForEach(radiusOptionsInMeters, id: \.self) { unit in
                                        Text("\(googlePlacesParams.radiusUnit == "km" ? Double(unit) / 1000.0 : Double(unit) / 1609.34, specifier: "%.1f") \(googlePlacesParams.radiusUnit)")
                                            .tag(unit)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                
                                Toggle("Use Metric (km)", isOn: Binding<Bool>(
                                    get: { googlePlacesParams.radiusUnit == "km" },
                                    set: { newValue in
                                        googlePlacesParams.radiusUnit = newValue ? "km" : "mi"
                                    }
                                ))
                                .toggleStyle(SwitchToggleStyle())
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                            )
                        }
                    }
                    .padding(20)
                }
                
                // Apply Button
                VStack(spacing: 0) {
                    Divider()
                    
                    Button(action: {
                        updateInitialState()
                        sharedAlertVM.currentAlertType = nil
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Apply Filters")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.accentColor)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(20)
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Reset") {
                    googlePlacesParams.resetFilters()
                    selectedSort = ""
                    selectedBrew = ""
                    updateInitialState()
                },
                trailing: Button("Done") {
                    self.presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            updateInitialState()
        }
    }
}

