//
//  FiltersView.swift
//  Brewies
//
//  Created by Noah Boyers on 6/23/23.
//

import SwiftUI

class YelpSearchParams: ObservableObject {
    @Published var radius: Int = 0
    @Published var businessType: String = "coffee" // This can be "coffee" or "brewery"
    @Published var sortBy: String = "distance" // This can be "distance", "best_match", "rating", "review_count"
    @Published var price: [String] = ["$"] // This can be ["$"], ["$$"], ["$$$"], ["$$$$"], or any combination
}

struct FiltersView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @ObservedObject var yelpParams: YelpSearchParams
    @EnvironmentObject var user: User
    @Environment(\.colorScheme) var colorScheme
    
    var businessTypes = ["coffee", "brewery"]
    var sortByOptions = ["distance", "best_match", "rating", "review_count"]
    var priceOptions = ["$", "$$", "$$$", "$$$$"]
    var unitOptions = [5000, 6000, 7000, 8000]
    @State private var selectedOption: Int = 0
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    //TODO: Close this sheet
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
                    //TODO: Reset the Settings Applied
                }) {
                    Text("Reset")
                        .font(.system(size: 20, weight: .medium))
                        .padding()
                        .font(.title3)
                        .foregroundColor(.teal)
                }
            }
            
            Spacer()
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
                                if let index = yelpParams.price.firstIndex(of: price) {
                                    // If price is already selected, remove it from the array
                                    yelpParams.price.remove(at: index)
                                } else {
                                    // If price is not selected, add it to the array
                                    yelpParams.price.append(price)
                                }
                            }) {
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
                    
                    Divider()
                    
                    Text("Search Radius")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    
                    Divider()
                    
                    //MARK: Distance
                    Text("Distance")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    
                    VStack(alignment: .leading) {
                        Divider()
                        //MARK: Brew Type
                        Text("Brew Type")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                    }
                }
            }
        }
    }
}
