//
//  StreakCounterView.swift
//  Brewies
//
//  Created by Noah Boyers on 10/20/23.
//

import SwiftUI


struct StreakTrackerView: View {
    @State private var lastWatchedDate: Date? = nil
    @State private var streakCount: Int = 0
    @State private var showCustomAlert: Bool = false
    @State private var showLoginAlert: Bool = false
    @ObservedObject private var userVM = UserViewModel.shared
    let signInCoordinator = SignInWithAppleCoordinator()
    var streakColor: Color {
        let weekCount = streakCount / 7
        switch weekCount {
        case 0: return .cyan
        case 1: return .green
        case 2: return .blue
        case 3: return .orange
        case 4: return .pink
        case 5: return .purple
        case 6: return .red
        default: return .yellow
        }
    }
    
    init() {
        let streakData = userVM.loadStreakData()
        _streakCount = State(initialValue: streakData.streakCount)
        _lastWatchedDate = State(initialValue: streakData.lastWatchedDate)
    }
    
    private func shouldAllowAd() -> Bool {
        guard let lastDate = lastWatchedDate else { return true }
        let elapsedHours = Calendar.current.dateComponents([.hour], from: lastDate, to: Date()).hour ?? 0
        return elapsedHours >= 24
        
    }
    
    private func showAd() {
        // Assume you have a function to show an ad and it will callback when completed
    }
    
    private func incrementStreak() {
        if shouldAllowAd() {
            streakCount += 1
        } else {
            streakCount = 0
        }
        saveStreakData()
    }
    
    private func saveStreakData() {
        userVM.saveStreakData(streakCount: streakCount, lastWatchedDate: lastWatchedDate)
    }
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    if shouldAllowAd() {
                        showCustomAlert = true
                    }
                }) {
                    Text("\(streakCount)")
                        .font(.caption)
                        .padding()
                        .background(Circle().fill(streakColor))
                        .foregroundColor(.white)
                }
                .padding()
            }
        }
        .overlay(
            Group {
                if showCustomAlert {
                    CustomAlertView(
                        title: "Watch an Ad",
                        message: "Watch the ad to increase your streak count",
                        watchAdAction: {
                            showAd()
                            showCustomAlert = false
                        },
                        dismissAction: {
                            showCustomAlert = false
                        }
                    )
                } else if showLoginAlert {
                    CustomAlertView(
                        title: "Sign In Required",
                        message: "Please sign in to continue",
                        goToStoreAction: {
                            // Provide action to navigate to sign in screen
                            showLoginAlert = false
                        },
                        dismissAction: {
                            showLoginAlert = false
                        }
                    )
                }
            }
        )
    }
}


#Preview {
    GeometryReader { geo in
        VStack {
            HStack {
                Spacer()
                StreakTrackerView()
                    .offset(x: -geo.size.width / 20, y: -geo.size.height * 0.80)
            }
            Spacer()
        }
    }
}
