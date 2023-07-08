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
    @State private var showSettings = false // State for showing SettingsView
    
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
                            .foregroundColor(.secondary)
                    }
                }
                .padding([.top, .horizontal], 20)
            }
            Divider()
            
            Spacer()
            Button(action: {
                self.showSettings = true
            }) {
                HStack {
                    Spacer()
                    Image(systemName: "gear")
                    Text("Settings")
                    Spacer()
                }
            }
            .padding()
            .foregroundColor(.primary)
            .background(.bar)
            .cornerRadius(10)
            .frame(width: 375)
            Spacer()
            
            // Add a sheet for SettingsView
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .sheet(isPresented: $showFavorites) {
            FavoritesView(showPreview: $showFavorites)
        }
        Spacer()
    }
}
