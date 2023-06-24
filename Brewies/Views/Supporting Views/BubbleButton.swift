//
//  BubbleButton.swift
//  Brewies
//
//  Created by Noah Boyers on 6/24/23.
//

import Foundation
import SwiftUI

struct BubbleButton: View {
    @Binding var selectedOption: String
    let option: String

    var body: some View {
        Button(action: {
            self.selectedOption = self.option
        }) {
            Text(option)
                .padding()
                .background(selectedOption == option ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .clipShape(Circle())
                .animation(.easeInOut(duration: 1.0), value: 0)
        }
    }
}
