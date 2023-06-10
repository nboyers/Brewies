//
//  SignInWithAppleButton.swift
//  Brewies
//
//  Created by Noah Boyers on 6/9/23.
//

import SwiftUI
import AuthenticationServices

struct SignInWithAppleButton: View {
    var action: () -> Void
    var label: String
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .foregroundColor(.white)
                .padding()
                .background(Color.black)
                .cornerRadius(8)
        }
        .signInWithAppleButtonStyle(.black)
    }
}
