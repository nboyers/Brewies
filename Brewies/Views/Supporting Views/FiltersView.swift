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
    @State private var radiusOptionsInMeters = [1609, 3219, 4828, 8047] // 1, 2, 3, 5 miles in meters
    @State private var selectedBrew = ""
    @State private var initialState: [String: Any] = [:]
    
    let radiusLabels = ["1 mi", "2 mi", "3 mi", "5 mi"]
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
                // Header
                HStack {
                    Button("Reset") {
                        googlePlacesParams.resetFilters()
                        selectedSort = "Prominence"
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(UIColor.systemBackground))
                
                Divider()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Price Range
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Price Range")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 12) {
                                ForEach(priceOptions, id: \.self) { price in
                                    Button(action: {
                                        priceButtonAction(price: price)
                                    }) {
                                        Text(price)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(googlePlacesParams.priceLevels.contains(price.count - 1) ? .white : .primary)
                                            .frame(width: 60, height: 40)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(googlePlacesParams.priceLevels.contains(price.count - 1) ? Color.blue : Color(UIColor.secondarySystemBackground))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(googlePlacesParams.priceLevels.contains(price.count - 1) ? Color.clear : Color(UIColor.separator), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                Spacer()
                            }
                        }
                        
                        // Sort By
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sort By")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 8) {
                                ForEach(sortOptions, id: \.self) { sortOption in
                                    Button(action: {
                                        selectedSort = sortOption
                                        googlePlacesParams.sortBy = apiSortOptions[selectedSort] ?? ""
                                    }) {
                                        HStack {
                                            Text(sortOption)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: selectedSort == sortOption ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedSort == sortOption ? .blue : .secondary)
                                                .font(.system(size: 20))
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Search Radius
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Search Radius")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("Search Radius", selection: $googlePlacesParams.radiusInMeters) {
                                ForEach(0..<radiusOptionsInMeters.count, id: \.self) { index in
                                    Text(radiusLabels[index]).tag(radiusOptionsInMeters[index])
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            selectedSort = googlePlacesParams.sortBy == "distance" ? "Distance" : "Prominence"
        }
    }
}

