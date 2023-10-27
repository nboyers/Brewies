////
////  UserProfileView.swift
////  Brewies
////
////  Created by Noah Boyers on 6/16/23.
////
//
import SwiftUI

struct UserProfileView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var contentViewModel: ContentViewModel
    @Binding var activeSheet: ActiveSheet?
    @State var showSettings  = false
    @State var changeName = false
    var body: some View {
        if userViewModel.user.isLoggedIn {
            VStack {
                VStack {
                    Button(action: {
                        showSettings = true
                    }) {
                        HStack {
                            Text(String(userViewModel.user.firstName.prefix(1)))
                                .foregroundColor(.white)
                                .font(.system(size: 30, weight: .bold))
                                .frame(width: 30, height: 30)
                                .background(RadialGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink]), center: .center, startRadius: 5, endRadius: 70))
                                .clipShape(Circle())
                            Text("\(userViewModel.user.firstName) \(userViewModel.user.lastName)")
                            
                            Spacer()
                            
                            Button(action: {
                                self.presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "x.circle.fill")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding([.top, .horizontal], 20)
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
                
                Divider()
                Spacer()
                Button(action: {
                    showSettings = true
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "gear")
                        Text("Settings")
                        Spacer()
                    }
                }
                .padding()
                .foregroundColor(.primary)
                .background(.bar)
                .cornerRadius(10)
                .frame(width: 375)
    
                Button(action: shareApp) {
                    HStack {
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Brewies")
                        Spacer()
                    }
                }
                .padding()
                .foregroundColor(.primary)
                .background(.bar)
                .cornerRadius(10)
                .frame(width: 375)
                 
                Button(action: leaveReview) {
                    HStack {
                        Spacer()
                        Image(systemName: "star.fill")
                        Text("Leave a Review")
                        Spacer()
                    }
                }
                .padding()
                .foregroundColor(.primary)
                .background(.bar)
                .cornerRadius(10)
                .frame(width: 375)
                Spacer()
            }
        }
    }
    private func shareApp() {
        activeSheet = .shareApp
    }
    
    
    private func leaveReview() {
        let reviewURL = URL(string: "https://apps.apple.com/us/app/brewies/id6450864433?action=write-review")!
        UIApplication.shared.open(reviewURL)
    }
    
}
