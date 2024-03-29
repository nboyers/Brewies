//
//  SignInWithAppleCoordinator.swift
//  Brewies
//
//  Created by Noah Boyers on 6/9/23.
//

import Foundation
import AuthenticationServices

class SignInWithAppleCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var userViewModel: UserViewModel
    
    override init() { // Initialize without User object
        self.userViewModel = UserViewModel.shared // Use singleton instance
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let window = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .compactMap { $0 }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first
        return window ?? UIWindow()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            // Here you update your User object with data from Apple ID
            DispatchQueue.main.async {
                self.userViewModel.user.isLoggedIn = true
                self.userViewModel.user.userID = userIdentifier.lowercased()
                self.userViewModel.user.firstName = fullName?.givenName ?? ""
                self.userViewModel.user.lastName = fullName?.familyName ?? ""
                self.userViewModel.user.email = email?.lowercased() ?? ""
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle sign-in error
        // print("Sign-in with Apple failed: \(error.localizedDescription)")
    }
    
    func startSignInWithAppleFlow() {
        // Create a nonce if you want to implement an additional layer of security
        let nonce = UUID().uuidString
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = nonce
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
        // Save the login status
        userViewModel.saveUserLoginStatus()
        userViewModel.syncCredits(accountStatus: "login")
    }
}
