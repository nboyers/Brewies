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
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
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
                  showStorefront   = true
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

#Preview {
    SettingsView()
        .environmentObject(UserViewModel())
}
