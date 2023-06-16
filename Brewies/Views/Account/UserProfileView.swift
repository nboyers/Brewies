////
////  UserProfileView.swift
////  Brewies
////
////  Created by Noah Boyers on 6/16/23.
////
//
import SwiftUI

struct UserProfileView: View {
    @ObservedObject var user: User
    
    var body: some View {
        VStack {
            // Since firstName and lastName are not optionals, we don't need to check them with `if let`
            Text("Name: \(user.firstName) \(user.lastName)")
            
            Button(action: {
                // Code to sign out the user
            }) {
                Text("Sign Out")
                    .font(.headline)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 50)
            
            Spacer()
        }
        .padding()
    }
}

////
////struct UserProfileView_Previews: PreviewProvider {
////    static var previews: some View {
////        UserProfileView()
////    }
////}
