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
   
    @State private var activeSheet: ActiveSheet?
    
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
                    Button(action: {
                        activeSheet = .userProfile // Change to the appropriate case
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
                        activeSheet = .storefront // Change to the appropriate case
                    }) {
                        Text("In-App Store")
                            .padding()
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                if userViewModel.user.isLoggedIn {
                    Button(action: {
                        userViewModel.signOut()
                        userViewModel.syncCredits()
                        self.presentationMode.wrappedValue.dismiss()
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
            .sheet(item: $activeSheet) { item in
                switch item {
                case .userProfile:
                    EditProfileView()
                case .storefront:
                    StorefrontView()
                default:
                    Text("Something went wrong")
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(UserViewModel())
    }
}
