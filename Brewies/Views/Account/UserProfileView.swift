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
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        VStack {
            VStack {
                GeometryReader { geo in
                    HStack {
                        Text("\(user.firstName) \(user.lastName)")
                            .lineLimit(1)
                            .padding(.horizontal)
                        
                        Spacer()
                            .frame(width: geo.size.width*0.75)
                        
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "x.circle.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .padding([.top, .horizontal], 20)
                }
                Divider()
            }
            Spacer()
        }
    }
}
