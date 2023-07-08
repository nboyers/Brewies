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
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                HStack {
                    Text("Settings")
                        .padding(.horizontal)
                        .bold()
                        .font(.largeTitle)
                    Spacer()
                }
                
                // NavigationLink to EditProfileView
                NavigationLink(destination: EditProfileView()) {
                    Text("Edit Profile")
                        .padding()
                        .font(.title2)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarHidden(true)  // Hides the default navigation bar
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(UserViewModel())
    }
}
