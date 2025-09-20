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
    var primaryButtonTitle: String?
    var primaryAction: (() -> Void)?
    var secondaryButtonTitle: String?
    var secondaryAction: (() -> Void)?
    var dismissAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with icon and close button
            HStack {
                Image(systemName: "creditcard.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: dismissAction ?? {}) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .padding(.bottom, 16)
            
            // Message
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .padding(.bottom, 24)
            
            // Action buttons
            VStack(spacing: 12) {
                if let primaryAction = primaryAction,
                   let primaryButtonTitle = primaryButtonTitle {
                    Button(action: primaryAction) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text(primaryButtonTitle)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                
                if let secondaryAction = secondaryAction,
                   let secondaryButtonTitle = secondaryButtonTitle {
                    Button(action: secondaryAction) {
                        HStack {
                            Image(systemName: "cart.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text(secondaryButtonTitle)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}


#Preview {
    CustomAlertView(
        title: "Search Credits Required",
        message: "You need search credits to discover new coffee shops and breweries in your area. Watch an ad to earn free credits or purchase a credit pack.",
        primaryButtonTitle: "Watch Ad for Credits",
        primaryAction: {},
        secondaryButtonTitle: "Purchase Credits",
        secondaryAction: {}
    )
}
