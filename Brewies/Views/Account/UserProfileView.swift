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
    
    let signInCoordinator = SignInWithAppleCoordinator()
    
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
                                .background(RadialGradient(gradient: Gradient(colors: [Color(hex: "#afece7"), Color(hex: "#8ba6a9"), Color(hex: "#75704e"), Color(hex: "#987284"), Color(hex: "#f4ebbe")]), center: .center, startRadius: 5, endRadius: 70))
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
                    SettingsView(activeSheet: $activeSheet)
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
        } else {
            GeometryReader { geometry in
                VStack {
                    Spacer() // Pushes the content to the center vertically
                    HStack {
                        Spacer() // Pushes the content to the center horizontally
                        Image("App_Logo.png")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5) // 50% of the width of the GeometryReader
                            .clipped()
                            .cornerRadius(10)
                        Spacer() // Pushes the content to the center horizontally
                    }
                    Spacer() // Pushes the content to the center vertically
                }
            }
            Spacer()
            SignInWithAppleButton(action: {
                signInCoordinator.startSignInWithAppleFlow()
            }, label: "Sign in with Apple")
            .frame(width: 280, height: 45)
            .padding([.top, .bottom], 50)
            .presentationDetents([.medium])
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
