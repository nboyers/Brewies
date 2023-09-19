//
//  SettingsView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/8/23.
//

import SwiftUI

struct SettingsView: View {
    @State var editProfileView = false
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
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
                if userViewModel.user.isLoggedIn {
                    // NavigationLink to EditProfileView
                    NavigationLink(destination: EditProfileView()) {
                        Text("Edit Profile")
                            .padding()
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                    
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
                NavigationLink(destination: StorefrontView()) {
                    HStack {
                        Text("In-App Store")
                            .padding()
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

                
                Spacer()
                if userViewModel.user.isLoggedIn {
                    Button(action: {
                        userViewModel.signOut()
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text("Sign Out")
                                .foregroundColor(.red)
                                .padding()
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
            }
            .padding()
            .navigationBarHidden(true)            
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(UserViewModel())
    }
}
