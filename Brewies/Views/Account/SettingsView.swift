//
//  SettingsView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/8/23.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.openURL) var openURL
    @State var showStorefront = false
    @State var editProfile = false
    @Binding var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                settingsHeader
                
                if userViewModel.user.isLoggedIn {
                    loggedInUserOptions
                } else {
                    loggedOutUserOptions
                }
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $showStorefront) {
                StorefrontView()
            }
        }
    }
    
    // MARK: - Subviews
    private var settingsHeader: some View {
        HStack {
            Spacer()
            Text("Settings")
                .padding()
                .bold()
                .font(.largeTitle)
            Spacer()
        }
    }
    
    private var loggedInUserOptions: some View {
        Group {
            actionButton(title: "Edit Profile", action: { editProfile = true })
            actionButton(title: "In-App Store", action: { showStorefront = true })
            termsAndPrivacyButtons
            signOutButton
        }
    }
    
    private var loggedOutUserOptions: some View {
        Group {
            actionButton(title: "Share Brewies", action: shareApp, imageName: "square.and.arrow.up")
            actionButton(title: "Leave a Review", action: leaveReview, imageName: "star.fill")
            termsAndPrivacyButtons
        }
    }
    
    private func actionButton(title: String, action: @escaping () -> Void, imageName: String? = nil) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                if let imageName = imageName {
                    Image(systemName: imageName)
                }
                Text(title)
                Spacer()
            }
            .padding()
            .foregroundColor(.primary)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
    }
    
    private var termsAndPrivacyButtons: some View {
        HStack {
            Spacer()
            termsOfServiceButton
            Spacer()
            privacyPolicyButton
            Spacer()
        }
    }
    
    private var termsOfServiceButton: some View {
        Button("terms of service") {
            openURL(termsOfServiceURL)
        }
        .font(.footnote)
    }
    
    private var privacyPolicyButton: some View {
        Button("privacy policy") {
            openURL(privacyPolicyURL)
        }
        .font(.footnote)
    }
    
    private var signOutButton: some View {
        Button("Sign Out") {
            userViewModel.signOut()
            userViewModel.syncCredits(accountStatus: "signOut")
        }
        .foregroundColor(.red)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
    
    // MARK: - Actions
    private func shareApp() {
        activeSheet = .shareApp
    }
    
    private func leaveReview() {
        guard let reviewURL = URL(string: "https://apps.apple.com/us/app/brewies/id6450864433?action=write-review") else { return }
        openURL(reviewURL)
    }
    
    // MARK: - URLs
    private var termsOfServiceURL: URL {
        URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    }
    
    private var privacyPolicyURL: URL {
        URL(string: "https://nobosoftware.com/privacy")!
    }
}
