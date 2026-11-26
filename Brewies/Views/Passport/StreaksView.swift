//
//  StreaksView.swift
//  Brewies
//

import SwiftUI

/// The Passport's streaks tab: loyalty to a favorite shop, a quick check-in, and a card to share.
struct StreaksView: View {
    let summary: StreakSummary
    let checkIn: (Shop) -> Void
    let select: (Shop) -> Void

    @State private var shareImage: UIImage?
    @State private var checkInCount = 0

    var body: some View {
        if let top = summary.top {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero(for: top)
                    journalCard
                    regulars
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .task(id: shareKey(for: top)) {
                shareImage = top.current > 0 ? StreakShareCard.image(for: top) : nil
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "flame")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 68, height: 68)
                    .background(Theme.accent.opacity(0.12), in: Circle())
                Text("Start a streak")
                    .font(.display(.title3))
                Text("Visit the same place two weeks in a row and it becomes a streak. Log a visit to begin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Hero

    private func hero(for streak: Streak) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(streak.tier.title, systemImage: "rosette")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Spacer()
                CategoryIcon(category: streak.shop.category, size: 20)
                    .foregroundStyle(Theme.accent.opacity(0.6))
            }

            Text(streak.shop.name)
                .font(.display(.title2, weight: .bold))
                .lineLimit(2)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(streak.current > 0 ? AnyShapeStyle(flame) : AnyShapeStyle(Color.secondary.opacity(0.4)))
                Text("\(streak.current)")
                    .font(.system(size: 60, weight: .bold, design: .serif))
                Text("week streak")
                    .font(.display(.headline))
                    .foregroundStyle(.secondary)
            }

            WeekDots(weeks: streak.recentWeeks)

            Text(status(for: streak))
                .font(.subheadline)
                .foregroundStyle(streak.isAtRisk ? Color.orange : .secondary)

            if let next = streak.visitsToNextTier {
                tierProgress(for: streak, next: next)
            }

            HStack(spacing: 10) {
                Button {
                    checkIn(streak.shop)
                    checkInCount += 1
                } label: {
                    Label(streak.visitedToday ? "Checked in today" : "Check in", systemImage: streak.visitedToday ? "checkmark" : "mappin.and.ellipse")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(streak.visitedToday)
                .opacity(streak.visitedToday ? 0.6 : 1)
                .sensoryFeedback(.success, trigger: checkInCount)

                shareButton(for: streak)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    @ViewBuilder
    private func shareButton(for streak: Streak) -> some View {
        if let shareImage {
            ShareLink(
                item: Image(uiImage: shareImage),
                message: Text("\(streak.current) weeks in a row at \(streak.shop.name) with Brewies."),
                preview: SharePreview("My \(streak.current)-week streak", image: Image(uiImage: shareImage))
            ) {
                Image(systemName: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 56)
                    .padding(.vertical, 16)
                    .background(Theme.accent.opacity(0.12), in: Capsule())
            }
            .accessibilityLabel("Share streak")
        }
    }

    private func tierProgress(for streak: Streak, next: (visits: Int, tier: RegularTier)) -> some View {
        let tier = streak.tier
        let span = max(1, next.tier.threshold - tier.threshold)
        let done = max(0, streak.totalVisits - tier.threshold)

        return VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: Double(min(done, span)), total: Double(span))
                .tint(Theme.accent)
            Text("\(next.visits) more \(next.visits == 1 ? "visit" : "visits") to become a \(next.tier.title)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func status(for streak: Streak) -> String {
        if streak.isAtRisk {
            return "Stop by before the week ends to keep your streak alive."
        }
        if streak.current == 0 {
            let weeks = Calendar.current.dateComponents([.weekOfYear], from: streak.lastVisit, to: Date()).weekOfYear ?? 0
            return weeks <= 1
                ? "Visit this week to start a new streak."
                : "Your last visit was \(weeks) weeks ago. Visit to start a new streak."
        }
        return streak.visitedThisWeek ? "You've been this week. See you next week." : ""
    }

    private var flame: LinearGradient {
        LinearGradient(colors: [.yellow, .orange, .red], startPoint: .top, endPoint: .bottom)
    }

    private func shareKey(for streak: Streak) -> String {
        "\(streak.shop.id)-\(streak.current)-\(streak.totalVisits)-\(streak.recentWeeks.map { $0 ? "1" : "0" }.joined())"
    }

    // MARK: - Journal and regulars

    private var journalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Across all shops")

            HStack(spacing: 0) {
                stat(value: "\(summary.journalCurrent)", label: "Weeks in a row")
                Rectangle().fill(Color.primary.opacity(0.08)).frame(width: 1, height: 32)
                stat(value: "\(summary.journalLongest)", label: "Longest ever")
                Rectangle().fill(Color.primary.opacity(0.08)).frame(width: 1, height: 32)
                stat(value: "\(summary.shops.filter { $0.current >= 2 }.count)", label: "Active regulars")
            }
            .padding(.vertical, 16)
            .card()

            Text("Weeks in a row counts a visit to any shop. Regulars have a streak of 2 weeks or more.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.display(.title2, weight: .bold))
                .foregroundStyle(Theme.accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var regulars: some View {
        let others = summary.shops.dropFirst().filter { $0.totalVisits >= 2 }
        if !others.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Your regulars")

                VStack(spacing: 0) {
                    ForEach(Array(others.enumerated()), id: \.element.id) { index, streak in
                        Button {
                            select(streak.shop)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(streak.shop.name)
                                        .font(.display(.headline))
                                        .lineLimit(1)
                                    Text("\(streak.tier.title) · \(streak.totalVisits) visits")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if streak.current > 0 {
                                    Label("\(streak.current)", systemImage: "flame.fill")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.orange)
                                }
                            }
                            .padding(14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < others.count - 1 {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
                .card()
            }
        }
    }
}

/// The last twelve weeks as dots, filled where the user visited. The final dot is this week.
private struct WeekDots: View {
    let weeks: [Bool]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { index, visited in
                    Circle()
                        .fill(visited ? Theme.accent : Color.primary.opacity(0.10))
                        .frame(width: 18, height: 18)
                        .overlay {
                            if index == weeks.count - 1 {
                                Circle().strokeBorder(Theme.accent, lineWidth: 2).padding(-4)
                            }
                        }
                }
            }
            .padding(.horizontal, 4)

            HStack {
                Text("12 weeks ago")
                Spacer()
                Text("This week")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Visited in \(weeks.filter { $0 }.count) of the last \(weeks.count) weeks")
    }
}
