//
//  BrewDetailView.swift
//  Brewies
//
//  Created by Noah Boyers on 5/15/23.
//

import SwiftUI
import SafariServices

import Kingfisher

struct BrewDetailView: View {
    var coffeeShop: CoffeeShop
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showSafariView = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ZStack(alignment: .topLeading) {
                    // Header image
                    KFImage(URL(string: coffeeShop.imageURL))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                    
                    // Dismiss Button
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrowshape.turn.up.backward.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.red.opacity(0.6))
                            .clipShape(Circle())
                            .padding(.top, 50)
                            .padding(.leading, 20)
                    }
                    
                    VStack {
                        Spacer()
                        VStack(alignment: .leading) {
                            // Coffee shop name
                            Text(coffeeShop.name)
                                .bold()
                                .font(.largeTitle)
                                .lineLimit(2)
                                .shadow(color: .black, radius: 3, x: 0, y: 0)
                            
                            // Rating and Review Count
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("\(coffeeShop.rating, specifier: "%.1f") (\(coffeeShop.reviewCount) reviews)")
                                    .font(.headline)
                                Spacer()
                            }
                            .bold()
                        }
                        .padding(.horizontal)
                    }
                }.edgesIgnoringSafeArea(.top)
                
                // Address
                HStack {
                    Image(systemName: "location.circle")
                    Button(action: {
                        openMapsAppWithDirections()
                    }) {
                        Text(coffeeShop.address)
                    }
                }
                .padding()
                
                // Phone
                HStack {
                    Image(systemName: "phone.circle")
                    Button(action: {
                        callCoffeeShop()
                    }) {
                        Text(coffeeShop.phone)
                    }
                }
                .padding(.horizontal)
                
                // Open Hours
                VStack(alignment: .leading) {
                      Text("Hours")
                          .font(.headline)
                          .padding(.top)
                      
                      Button(action: {
                          openCoffeeShopWebsite()
                      }) {
                          HStack {
                              Image(systemName: "globe")
                              Text("Visit website")
                          }
                          .padding()
                          .foregroundColor(.white)
                          .background(Color.blue)
                          .cornerRadius(8)
                      }
                      .sheet(isPresented: $showSafariView) {
                          if let url = URL(string: coffeeShop.url) {
                              SafariView(url: url)
                          }
                      }
                      .padding()
                  }
            }
            .navigationBarItems(trailing: closeButton)
        }
        .edgesIgnoringSafeArea(.top)
    }
    
    private var closeButton: some View {
        Button("Close") {
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func openMapsAppWithDirections() {
        let destination = "\(coffeeShop.latitude),\(coffeeShop.longitude)"
        let formattedDestination = destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = "http://maps.apple.com/?daddr=\(formattedDestination)"
        if let url = URL(string: url), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func callCoffeeShop() {
        let phoneNumber = coffeeShop.phone
        if let url = URL(string: "tel://\(phoneNumber)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openCoffeeShopWebsite() {
        showSafariView = true
    }

}
