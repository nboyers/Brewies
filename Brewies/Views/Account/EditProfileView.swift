//
//  EditProfileView.swift
//  Brewies
//
//  Created by Noah Boyers on 7/8/23.
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Form {
                Section(header: Text("First Name")) {
                    TextField("First Name", text: $firstName)
                }
                
                Section(header: Text("Last Name")) {
                    TextField("Last Name", text: $lastName)
                }
                
                Section {
                    Button(action: {
                        saveChanges()
                    }) {
                        Text("Save Changes")
                    }
                }
            }
            .onAppear(perform: loadUserData)
            .navigationTitle("Edit Profile")
         
            
            if isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            }
        }
    }
    
    func loadUserData() {
        firstName = userViewModel.user.firstName
        lastName = userViewModel.user.lastName
    }
    
    func saveChanges() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            userViewModel.user.firstName = firstName
            userViewModel.user.lastName = lastName
            isLoading = false
            
            // Here, you would typically save the changes to persistent storage.
            userViewModel.saveUserLoginStatus()
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
            .environmentObject(UserViewModel())
    }
}
