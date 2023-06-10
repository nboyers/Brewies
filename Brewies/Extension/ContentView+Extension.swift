//
//  ContentView+Extension.swift
//  Brewies
//
//  Created by Noah Boyers on 6/9/23.
//

//import Foundation
//import SwiftUI
//import AuthenticationServices
//
//
//extension ContentView: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
//    // Implement the delegate methods as needed
//    // For example, you can handle the success and failure cases
//    
//    
//    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
//        // Handle successful sign-in
//        
//        // Check if the authorization credential is of type ASAuthorizationAppleIDCredential
//        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
//            return
//        }
//        
//        // Retrieve the user's unique identifier
//        let userIdentifier = appleIDCredential.user
//        print("User Identifier: \(userIdentifier)")
//        
//        // Retrieve the user's full name if available
//        if let fullName = appleIDCredential.fullName {
//            let givenName = fullName.givenName ?? ""
//            let familyName = fullName.familyName ?? ""
//            print("Full Name: \(givenName) \(familyName)")
//        }
//        
//        // Retrieve the user's email if available
//        let email = appleIDCredential.email ?? ""
//        print("Email: \(email)")
//        
//        // Perform any additional steps required with the sign-in data
//        
//        // ...
//    }
//    
//    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
//        // Handle sign-in error
//        // You can create a State variable to show an alert when the sign-in fails
//        print("Sign-in with Apple failed: \(error.localizedDescription)")
//    }
//    
//    // Provide a presentation anchor for the authorization controller
//    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
//        return self.window ?? UIWindow()
//    }
//
//}
