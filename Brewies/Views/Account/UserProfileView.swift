////
////  UserProfileView.swift
////  Brewies
////
////  Created by Noah Boyers on 6/16/23.
////
//
import SwiftUI

struct UserProfileView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var showFavorites = false
    @ObservedObject var contentViewModel: ContentViewModel

    init(userViewModel: UserViewModel, contentViewModel: ContentViewModel) {
        self.userViewModel = userViewModel
        self.contentViewModel = contentViewModel
    }

    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text(String(userViewModel.user.firstName.prefix(1)))
                        .foregroundColor(.white)
                        .font(.system(size: 30, weight: .bold))
                        .frame(width: 30, height: 30)
                        .background(RadialGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink]), center: .center, startRadius: 5, endRadius: 70))
                        .clipShape(Circle())
                    Text("\(userViewModel.user.firstName) \(userViewModel.user.lastName)")
                    
                    Spacer()
                    
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "x.circle.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.primary)
                    }
                }
                .padding([.top, .horizontal], 20)
            }
            Divider()
            
            VStack {
                // Favorites
                Button(action: {
                    self.showFavorites = true
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                            .resizable()
                            .scaledToFit() // Maintain aspect ratio
                            .frame(width: 20, height: 20) // Specify the size of the image
                            .foregroundColor(.white) // Color of the star
                            .background(Color.yellow) // Background color of the circle
                            .clipShape(Circle()) // Make the background a circle
                        Text("Favorites")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // Watch Ads
                Button(action: {
                    // Your action to handle the ad goes here
                    self.contentViewModel.handleRewardAd()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "video.fill")
                            .resizable()
                            .scaledToFit() // Maintain aspect ratio
                            .frame(width: 20, height: 20) // Specify the size of the image
                            .foregroundColor(.white) // Color of the star
                            .padding(5) // Add some padding to give the image more room
                            .background(Color.blue) // Background color of the circle
                            .clipShape(Circle()) // Make the background a circle
                        Text("Watch Ads for Credits")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
            }
            // Settings
        }
        .sheet(isPresented: $showFavorites) {
            FavoritesView(showPreview: $showFavorites) // A new view that you'll create to show the favorite shops
        }
        Spacer()
    }
}
