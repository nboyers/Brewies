//
//  FiltersView.swift
//  Brewies
//
//  Created by Noah Boyers on 6/23/23.
//

//TODO: FIX THE RESET BUTTON Currently shows "Apply (3)" and needs to be "Apply"
import SwiftUI

class YelpSearchParams: ObservableObject {
    @Published var radiusInMeters: Int = 8047 // start with 5 miles in meters
    @Published var radiusUnit: String = "mi" // Default unit is miles now
    @Published var businessType: String = ""
    @Published var sortBy: String = ""
    @Published var price: [String] = []
    
    func resetFilters() {
        self.radiusInMeters = 8047 // reset to 5 miles
        self.radiusUnit = "mi"
        self.businessType = ""
        self.sortBy = ""
        self.price = []
    }
}

struct FiltersView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var yelpParams: YelpSearchParams
    
    @EnvironmentObject var user: User
    
    
    @State private var applyChangesCount: Int = 0
    @State private var selectedSort: String = ""
    @State private var selectedOption: Int = 0
    @State private var radiusOptionsInMeters = [8047, 16093, 24140, 32186]
    @State private var selectedBrew = ""
    @State private var initialState: [String: Any] = [:]
    
    
    let sortOptions = ["Recommended", "Distance", "Rating", "Review"]
    let apiSortOptions: [String: String] = ["Recommended": "best_match", "Distance": "distance", "Rating": "rating", "Review": "review_count"]
    let priceOptions = ["$", "$$", "$$$", "$$$$"]
    let brewType = ["Coffee Shops", "Breweries"]
    
    private func changesCount() -> Int {
        var changesCount = 0
        if let initialPrice = initialState["price"] as? [String] {
            let addedPrice = yelpParams.price.filter { !initialPrice.contains($0) }
            let removedPrice = initialPrice.filter { !yelpParams.price.contains($0) }
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
        initialState["price"] = yelpParams.price
    }
    
    private func priceButtonAction(price: String) {
        if let index = yelpParams.price.firstIndex(of: price) {
            // If price is already selected, remove it from the array
            yelpParams.price.remove(at: index)
        } else {
            // If price is not selected, add it to the array
            yelpParams.price.append(price)
        }
    }
    
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                    // Reset the Settings Applied
                    yelpParams.resetFilters()
                    // Also reset the UI
                    selectedSort = ""
                    selectedBrew = ""
                    
                    // Reset the initial state
                    initialState = [:]
                    // Then reset the changes count
                    applyChangesCount = 0
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
                    // Reset the Settings Applied
                    yelpParams.resetFilters()
                    // Also reset the UI
                    selectedSort = ""
                    selectedBrew = ""
                    
                    // Reset the initial state
                    initialState = [:]
                    // Then reset the changes count
                    applyChangesCount = 0
                    
                }) {
                    Text("Reset")
                        .font(.system(size: 20, weight: .medium))
                        .padding()
                        .font(.title3)
                        .foregroundColor(.teal)
                }
            }
            Divider()
            ScrollView {
                VStack(alignment: .leading) {
                    //MARK: Search Radius
                    Text("Price")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    HStack(alignment: .center, spacing: 10) {
                        Spacer()
                        ForEach(priceOptions, id: \.self) { price in
                            Button(action: {
                                priceButtonAction(price: price)
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
                    Divider()
                    
                    Text("Sort")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    VStack(alignment: .leading) {
                        ForEach(sortOptions, id: \.self) { sortOption in
                            HStack {
                                Text(sortOption)
                                    .font(.body)
                                Spacer()
                                Button(action: {
                                    selectedSort = sortOption
                                    yelpParams.sortBy = apiSortOptions[selectedSort] ?? ""
                                }) {
                                    Circle()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(selectedSort == sortOption ? .blue : .clear)
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(colorScheme == .dark ? Color.white : Color.black, lineWidth: selectedSort == sortOption ? 0 : 1)
                                        )
                                }
                                
                            }.padding(.horizontal)
                        }
                    }
                    Divider()
                    
                    VStack(alignment: .leading) {
                        Text("Search Radius")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        Picker("Search Radius", selection: $yelpParams.radiusInMeters) {
                            ForEach(radiusOptionsInMeters, id: \.self) { unit in
                                Text("\(yelpParams.radiusUnit == "km" ? Double(unit)/1000.0 : Double(unit)/1609.34, specifier: "%.2f") \(yelpParams.radiusUnit)").tag(unit)
                            }
                        }.pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                        
                        Toggle(isOn: Binding<Bool>(
                            get: { yelpParams.radiusUnit == "km" },
                            set: { newValue in
                                yelpParams.radiusUnit = newValue ? "km" : "mi"
                                // Change the radius options when the unit changes
                            }
                        ), label: { Text(yelpParams.radiusUnit == "km" ? "Metric" : "Imperial") })
                        .padding(.horizontal)
                    }
                    
                    
                    VStack(alignment: .leading) {
                        Divider()
                        //MARK: Brew Type
                        Text("Business Category")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        VStack(alignment: .leading) {
                            ForEach(brewType, id: \.self) { brewOption in
                                HStack {
                                    Text(brewOption)
                                        .font(.body)
                                    Spacer()
                                    Button(action: {
                                        selectedBrew = brewOption
                                        yelpParams.businessType = selectedBrew
                                    }) {
                                        Circle()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(selectedBrew == brewOption ? .blue : .clear)
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(colorScheme == .dark ? Color.white : Color.black, lineWidth: selectedBrew == brewOption ? 0 : 1)
                                            )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom)
                    .onAppear {
                        initialState["radiusInMeters"] = yelpParams.radiusInMeters
                        initialState["radiusUnit"] = yelpParams.radiusUnit
                        initialState["businessType"] = yelpParams.businessType
                        initialState["sortBy"] = yelpParams.sortBy
                        initialState["price"] = yelpParams.price
                    }
                }
            }
            .onAppear {
                updateInitialState()
            }
        }
        HStack(alignment: .center) {
            Spacer()
                .frame(width: 25)
            
            GeometryReader { geo in
                  Button(action: {
                      // Apply changes
                      updateInitialState()
                  }) {
                      let changesCount = self.changesCount()
                      Text("Apply\(changesCount > 0 ? " (\(changesCount))" : "")")
                          .frame(width: geo.size.width, height: 50)
                          .background(.red)
                          .foregroundColor(.white)
                  }
                  .cornerRadius(15)
              }
            Spacer()
                .frame(width: 25)
        }
        .frame(maxHeight: 75)
    }
}
