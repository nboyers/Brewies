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
    var primaryButtonTitle: String? // New parameter for the primary button title
    var primaryAction: (() -> Void)? // Renamed from `goToStoreAction`
    var secondaryButtonTitle: String? // New parameter for the primary button title
    var secondaryAction: (() -> Void)?
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
                if let primaryAction = primaryAction,
                   let primaryButtonTitle = primaryButtonTitle { // Check if both action and title are provided
                    Button(action: primaryAction) {
                        Text(primaryButtonTitle)
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


#Preview {
    CustomAlertView(title: "TEST", message: "TEST", primaryButtonTitle: "Primary Button", primaryAction: nil, secondaryButtonTitle: "Secondary Button")
}
