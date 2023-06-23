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
    @Published var price: String = "$" // This can be "$", "$$", "$$$", "$$$$"
}

struct FiltersView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @ObservedObject var yelpParams: YelpSearchParams
    @EnvironmentObject var user: User
    
    var businessTypes = ["coffee", "brewery"]
    var sortByOptions = ["distance", "best_match", "rating", "review_count"]
    var priceOptions = ["$", "$$", "$$$", "$$$$"]
    var unitOptions = ["miles", "kilometers"]
    
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
            //MARK: Search Radius
            Text("Search Radius")
                .font(.largeTitle)
                .bold()
                .padding(.horizontal)
            if user.isLoggedIn && user.isSubscribed {
                
            }
            Divider()
            
            //MARK: Distance
            Text("Distance")
                .font(.largeTitle)
                .bold()
                .padding(.horizontal)
            if user.isLoggedIn && user.isSubscribed {
                
            }
            Divider()
            
            //MARK: Brew Type
            Text("Brew Type")
                .font(.largeTitle)
                .bold()
                .padding(.horizontal)
//            if user.isLoggedIn && user.isSubscribed {
//
//            }
        }
    }
    
    private  func convertMetersToMiles(meters: Int) -> Int {
        return Int(round(Double(meters) * 0.000621371))
    }
    
}
