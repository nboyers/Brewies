//
//  RootView.swift
//  Brewies
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Query private var visits: [Visit]
    @AppStorage("streakReminders") private var streakReminders = false

    var body: some View {
        TabView {
            Tab("Explore", systemImage: "map") {
                ExploreView()
            }
            Tab("Passport", systemImage: "book.closed") {
                PassportView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .tint(Theme.accent)
        .task {
            #if DEBUG
            DebugSeed.seedIfRequested(into: modelContext)
            #endif
        }
        // Re-plan the weekly reminder when visits change, the setting changes, or the app returns to the foreground.
        .task(id: "\(visits.count)|\(streakReminders)|\(scenePhase == .active)") {
            let summary = StreakSummary(visits: visits.map { StreakVisit(shop: Shop(visit: $0), date: $0.visitedAt) })
            await StreakReminders.update(summary: summary, enabled: streakReminders)
        }
    }
}
