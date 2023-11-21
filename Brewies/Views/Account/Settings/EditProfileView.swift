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
    @State var showDeleteAlert = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        ZStack {
            Form {
                Section(header: Text("Name")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }
                
                Section {
                    Button(action: {
                        saveChanges()
                        self.presentationMode.wrappedValue.dismiss()
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
            Button(action: {
                showDeleteAlert = true
            }) {
                Text("Delete Account")
                    .foregroundColor(.red)
                    .padding()
                    .font(.title2)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            if showDeleteAlert {
                CustomAlertView(title: "Are you sure?",
                                message: "All your saved progress will be wiped forever and cannot be retrieved.",
                                primaryButtonTitle: "Go back",
                                primaryAction: {
                    showDeleteAlert = false
                },
                                secondaryButtonTitle: "Delete Forever",
                                secondaryAction: {
                    userViewModel.deleteUserData()
                    userViewModel.signOut()
                    showDeleteAlert = false
                },
                                dismissAction: {
                    showDeleteAlert = false
                })

            }
        }
    }
    
    
    func loadUserData() {
        firstName = userViewModel.user.firstName
        lastName = userViewModel.user.lastName
    }
    
    func saveChanges() {
        isLoading = true
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            userViewModel.user.firstName = firstName
            userViewModel.user.lastName = lastName
            isLoading = false
            
            // Here, you would typically save the changes to persistent storage.
            userViewModel.saveUserLoginStatus()
//        }
    }
}

#Preview {
    EditProfileView()
        .environmentObject(UserViewModel())
}
