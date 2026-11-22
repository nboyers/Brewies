//
//  SettingsView.swift
//  Brewies
//

import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @Environment(StoreManager.self) private var store

    @Query private var visits: [Visit]

    @AppStorage("streakReminders") private var streakReminders = false

    @State private var showPaywall = false
    @State private var showManageSubscription = false

    private let appStoreURL = URL(string: "https://apps.apple.com/us/app/brewies/id6450864433")!
    private let reviewURL = URL(string: "https://apps.apple.com/us/app/brewies/id6450864433?action=write-review")!
    private let privacyURL = URL(string: "https://nobosoftware.com/privacy")!
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "–"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    proCard
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    exportRow
                    LabeledContent {
                        Text(store.isPro ? "On" : "Pro")
                            .foregroundStyle(store.isPro ? Theme.accent : .secondary)
                    } label: {
                        Label("iCloud Sync", systemImage: "icloud")
                    }
                } header: {
                    Text("Your data")
                } footer: {
                    Text(store.isPro
                         ? "Your visits and saved shops sync with iCloud when you're signed in."
                         : "Your visits and saved shops are stored on this device. Pro syncs them with iCloud.")
                }

                Section {
                    Toggle(isOn: $streakReminders) {
                        Label("Streak reminders", systemImage: "bell")
                    }
                } header: {
                    Text("Streaks")
                } footer: {
                    Text("A gentle nudge, at most once a week, when a streak is about to lapse.")
                }

                Section {
                    ShareLink(item: appStoreURL) {
                        Label("Share Brewies", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        openURL(reviewURL)
                    } label: {
                        Label("Rate on the App Store", systemImage: "star")
                    }
                }

                Section("Legal") {
                    Button("Privacy Policy") { openURL(privacyURL) }
                    Button("Terms of Use") { openURL(termsURL) }
                }

                Section {
                    LabeledContent("Version", value: versionText)
                }
            }
            .scrollContentBackground(.hidden)
            .paperBackground()
            .safeAreaInset(edge: .top, spacing: 0) {
                Text("Settings")
                    .font(.display(.largeTitle, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .background(Theme.background)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: streakReminders) {
                // Ask for notification permission when reminders are switched on, and switch back off if refused.
                guard streakReminders else { return }
                Task {
                    if await StreakReminders.requestAuthorization() == false {
                        streakReminders = false
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .manageSubscriptionsSheet(isPresented: $showManageSubscription)
        }
    }

    // MARK: - Pro

    private var proCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Theme.accent)
                    CategoryIcon(category: .coffee, size: 22)
                        .foregroundStyle(.white)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.isPro ? "Brewies Pro" : "Upgrade to Brewies Pro")
                        .font(.display(.headline))
                    Text(store.isPro
                         ? "Thanks for supporting Brewies."
                         : "Sync with iCloud, see your insights, and export your journal.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            if store.isPro {
                Button("Manage Subscription") { showManageSubscription = true }
                    .buttonStyle(.bordered)
                    .tint(Theme.accent)
            } else {
                Button("See Brewies Pro") { showPaywall = true }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var exportRow: some View {
        if store.isPro {
            ShareLink(item: JournalExport(visits: visits), preview: SharePreview("Brewies Journal.csv")) {
                Label("Export Journal", systemImage: "tablecells")
            }
            .disabled(visits.isEmpty)
        } else {
            Button {
                showPaywall = true
            } label: {
                LabeledContent {
                    Text("Pro").foregroundStyle(.secondary)
                } label: {
                    Label("Export Journal", systemImage: "tablecells")
                }
            }
            .tint(.primary)
        }
    }
}
