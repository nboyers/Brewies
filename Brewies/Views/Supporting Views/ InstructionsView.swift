//
//   InstructionsView.swift
//  Brewies
//
//  Created by Noah Boyers on 10/24/23.
//

import SwiftUI

struct InstructionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Daily Check-in Instructions")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                Text("1. Daily Check-in:")
                    .font(.headline)
                    .bold()
                Text("- Every 24 hours, you have the opportunity to 'check in' by watching an advertisement. Once you watch the ad, a point will be added to your account.")
                
                Text("2. Streak Indicator:")
                    .font(.headline)
                    .bold()
                
                Text("- You are awarded a new Check In color every 7 days that you keep the streak. A streak is kept by checking in daily.")
                
                Text("3. Weekly Bonus:")
                    .font(.headline)
                    .bold()
                Text("- With a 7-day streak, every week you get an option to receive 3 Discover credits or 2 Favorites view. Choose wisely!")
                
                Text("4. Streak Reset:")
                    .font(.headline)
                    .bold()
                Text("- Missing a daily check-in resets your streak back to zero. You'll need to rebuild your streak to qualify for the weekly bonus again.")
                Divider()
                Text("NOTE")
                    .font(.headline)
                    .bold()
                Text("- SOMETIMES CHECK IN ARE NOT READY, AND THIS WILL APPEAR. JUST CLICK THE BUTTON AGAIN TO RETRY")
            }
            .padding()
        }
        .navigationBarTitle("How Daily Check-in Works", displayMode: .inline)
    }
}

#Preview {
    InstructionsView()
}
