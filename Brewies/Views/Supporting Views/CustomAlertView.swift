//
//  CustomAlertView.swift
//  Brewies
//
//  Created by Noah Boyers on 9/4/23.
//

import SwiftUI

struct CustomAlertView: View {
    var title: String
    var message: String
    var goToStoreAction: (() -> Void)?
    var watchAdAction: (() -> Void)?
    var dismissAction: (() -> Void)?
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: dismissAction ?? {}) {
                    Image(systemName: "xmark")
                }
                .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
            
            HStack {
                Spacer()
                if let goToStoreAction = goToStoreAction {
                    Button(action: goToStoreAction) {
                        Text("Go to Store")
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                
                if let watchAdAction = watchAdAction {
                    Button(action: watchAdAction) {
                        Text("Watch Ad")
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
            }
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
        .frame(width: 270)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 6)
    }
}


struct CustomAlertView_Previews: PreviewProvider {
    static var previews: some View {
        CustomAlertView(
            title: "Test",
            message: "You have some error",
            goToStoreAction: {},
            watchAdAction: {},
            dismissAction: {}
        )
    }
}
