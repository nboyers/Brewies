//
//  SettingsView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/8/23.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var showStorefront = false
    @State var editProfile = false
    @Binding var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if userViewModel.user.isLoggedIn {
                    HStack {
                        Text("Settings")
                            .padding()
                            .bold()
                            .font(.largeTitle)
                        Spacer()
                    }
                    
                    Button(action: {
                        editProfile = true
                    }) {
                        Text("Edit Profile")
                            .padding()
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    
                    Button(action: {
                        showStorefront = true
                    }) {
                        Text("In-App Store")
                            .padding()
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    
                    
                    Spacer()
                    Button(action: {
                        userViewModel.signOut()
                        userViewModel.syncCredits(accountStatus: "signOut")
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .padding()
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                } else {
                    Button(action: shareApp) {
                        HStack {
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Brewies")
                            Spacer()
                        }
                    }
                    .padding()
                    .foregroundColor(.primary)
                    .background(.bar)
                    .cornerRadius(10)
                    .frame(width: 375)
                     
                    Button(action: leaveReview) {
                        HStack {
                            Spacer()
                            Image(systemName: "star.fill")
                            Text("Leave a Review")
                            Spacer()
                        }
                    }
                    .padding()
                    .foregroundColor(.primary)
                    .background(.bar)
                    .cornerRadius(10)
                    .frame(width: 375)
                }
                
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $showStorefront) {
                StorefrontView()
            }
            .sheet(isPresented: $editProfile) {
                EditProfileView()
            }
        }
    }
    private func shareApp() {
        activeSheet = .shareApp
    }
    
    
    private func leaveReview() {
        let reviewURL = URL(string: "https://apps.apple.com/us/app/brewies/id6450864433?action=write-review")!
        UIApplication.shared.open(reviewURL)
    }
    
}

