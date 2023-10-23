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
    @State private var  showAdAlert: Bool = false
    @State private var showLoginAlert: Bool = false
    @State private var showTimeLeftAlert: Bool = false
    @State private var showInstructionsAlert: Bool = false
    
    let sharedState = SharedAlertViewModel()
    
    
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
    
    private func timeLeft() -> String {
        guard let lastDate = lastWatchedDate else { return "" }
        let elapsedHours = Calendar.current.dateComponents([.hour], from: lastDate, to: Date()).hour ?? 0
        let remainingHours = 24 - elapsedHours
        let nextCheckInDate = Calendar.current.date(byAdding: .hour, value: remainingHours, to: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: nextCheckInDate ?? Date())
    }

    
    private func shouldAllowAd() -> String {
        // User is not logged in
        if !userVM.user.isLoggedIn {
            showLoginAlert = true
            return "No_Login"
        }
        
        // Check if it's been 24 hours since the last check-in.
        guard let lastDate = lastWatchedDate else {
            // It hasn't been 24hrs
            return "Too_Soon"
        }
        
        let elapsedHours = Calendar.current.dateComponents([.hour], from: lastDate, to: Date()).hour ?? 0
        
        if elapsedHours >= 24 && userVM.user.isLoggedIn {
            // It's been 24 hours, prompt to watch ad
            return "Reward_User"
        }
        return "Show_Instructions"
    }
    
    
    private func showAd() {
        //TODO: CREATE SHOW ADD FUNCTION
    }
    
    private func incrementStreak() {
        switch shouldAllowAd() {
            
        default:
            saveStreakData()
        }
        
    }
    
    private func saveStreakData() {
        userVM.saveStreakData(streakCount: streakCount, lastWatchedDate: lastWatchedDate)
    }
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        switch shouldAllowAd() {
                        case "No_Login": // User is not logged in
                            sharedState.showLoginAlert = true
                            
                        case "Too_Soon": // User comes before 24hrs
                            sharedState.showTimeLeftAlert = true
                            
                        case "Reward_User":  // User is logged in & over 24hrs since last checkin
                            sharedState.showAdAlert = true
                            
                        default: // Show them how to use the System
                            sharedState.showInstructions = true
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
            
        }
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
