//
//  SettingsView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/8/23.
//

import SwiftUI

struct SettingsView: View {
    @State var editProfileView = false
    @State private var showShareSheet = false
    
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
                
                Button(action: shareApp) {
                    HStack {
                        Text("Share Brewies")
                            .padding()
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                
                Button(action: leaveReview) {
                    HStack {
                        Text("Leave a Review")
                            .padding()
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

                Spacer()
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
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [URL(string: "https://apps.apple.com/us/app/brewies/id6450864433")!])
                    .presentationDetents([.medium])
            }
            
        }
    }
    
    private func shareApp() {
        let appURL = URL(string: "https://apps.apple.com/us/app/brewies/id6450864433")!
        showShareSheet = true
    }
    
    
    private func leaveReview() {
        let reviewURL = URL(string: "https://apps.apple.com/us/app/brewies/id6450864433?action=write-review")!
        UIApplication.shared.open(reviewURL)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(UserViewModel())
    }
}
