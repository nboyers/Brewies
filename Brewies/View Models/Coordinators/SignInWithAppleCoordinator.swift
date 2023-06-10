//
//  SignInWithAppleCoordinator.swift
//  Brewies
//
//  Created by Noah Boyers on 6/9/23.
//

import Foundation
import AuthenticationServices

class SignInWithAppleCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
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
        // Handle successful sign-in
        guard authorization.credential is ASAuthorizationAppleIDCredential else {
            return
        }

        // Handle the authorized sign in here
        // For example, you can store the user identifier, name, and email in your app
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle sign-in error
        print("Sign-in with Apple failed: \(error.localizedDescription)")
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
    }
}
