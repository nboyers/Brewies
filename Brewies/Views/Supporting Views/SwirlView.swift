//
//  SwirlView.swift
//  Brewies
//
//  Created by Noah Boyers on 10/27/23.
//

import SwiftUI

struct SwirlView: View {
    var color1: Color
    var color2: Color

    @available(iOS 16.4, *)
    var body: some View {
        ZStack {
            AngularGradient(gradient: Gradient(colors: [color1, color2, color1]), center: .center, startAngle: .zero, endAngle: .degrees(360))
        }
        .mask(Circle())
    }
}


#Preview {
    SwirlView(color1: .cyan, color2: .green)
        .frame(width: 100, height: 100) 
}
