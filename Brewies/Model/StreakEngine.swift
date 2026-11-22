//
//  StreakEngine.swift
//  Brewies
//
//  Works out how consistently the user visits each shop. A streak is the number of
//  consecutive calendar weeks with at least one visit.
//

import Foundation

/// The minimum a visit needs to contribute to a streak, so the logic doesn't depend on SwiftData.
struct StreakVisit {
    let shop: Shop
    let date: Date
}

enum RegularTier: Int, CaseIterable {
    case newcomer
    case regular
    case local
    case fixture

    init(visits: Int) {
        switch visits {
        case 20...: self = .fixture
        case 8...: self = .local
        case 3...: self = .regular
        default: self = .newcomer
        }
    }

    var title: String {
        switch self {
        case .newcomer: return "Newcomer"
        case .regular: return "Regular"
        case .local: return "Local"
        case .fixture: return "Fixture"
        }
    }

    /// Visits needed to reach this tier.
    var threshold: Int {
        switch self {
        case .newcomer: return 0
        case .regular: return 3
        case .local: return 8
        case .fixture: return 20
        }
    }

    var next: RegularTier? {
        RegularTier(rawValue: rawValue + 1)
    }
}

struct Streak: Identifiable {
    var id: String { shop.id }

    let shop: Shop
    /// Consecutive weeks with a visit, counting back from this week (or last week, until this week ends).
    let current: Int
    let longest: Int
    let totalVisits: Int
    let visitedThisWeek: Bool
    let visitedToday: Bool
    let lastVisit: Date
    /// Whether each of the last 12 weeks included a visit, oldest first.
    let recentWeeks: [Bool]

    var tier: RegularTier { RegularTier(visits: totalVisits) }

    /// A streak that ends if the user doesn't visit before this week is over.
    var isAtRisk: Bool { current > 0 && !visitedThisWeek }

    /// Visits still needed for the next tier, or nil at the top tier.
    var visitsToNextTier: (visits: Int, tier: RegularTier)? {
        guard let next = tier.next else { return nil }
        return (next.threshold - totalVisits, next)
    }
}

struct StreakSummary {
    /// Every shop with at least one visit, with the most committed first.
    let shops: [Streak]
    /// Consecutive weeks with a visit to any shop.
    let journalCurrent: Int
    let journalLongest: Int

    /// The shop the user is most loyal to.
    var top: Streak? { shops.first }

    init(visits: [StreakVisit], now: Date = Date(), calendar: Calendar = .current) {
        let engine = StreakEngine(now: now, calendar: calendar)

        let byShop = Dictionary(grouping: visits, by: \.shop.id)
        shops = byShop.values
            .compactMap { engine.streak(for: $0) }
            .sorted { lhs, rhs in
                (lhs.current, lhs.totalVisits, lhs.lastVisit) > (rhs.current, rhs.totalVisits, rhs.lastVisit)
            }

        let run = engine.run(weeks: engine.weekStarts(of: visits.map(\.date)))
        journalCurrent = run.current
        journalLongest = run.longest
    }
}

struct StreakEngine {
    static let recentWeekCount = 12

    let now: Date
    let calendar: Calendar

    private var thisWeekStart: Date {
        calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
    }

    func streak(for visits: [StreakVisit]) -> Streak? {
        guard let latest = visits.max(by: { $0.date < $1.date }) else { return nil }
        let weeks = weekStarts(of: visits.map(\.date))
        let run = run(weeks: weeks)

        let recent = (0..<Self.recentWeekCount).reversed().map { offset in
            weeks.contains(week(offset: -offset, from: thisWeekStart))
        }

        return Streak(
            shop: latest.shop,
            current: run.current,
            longest: run.longest,
            totalVisits: visits.count,
            visitedThisWeek: weeks.contains(thisWeekStart),
            visitedToday: visits.contains { calendar.isDate($0.date, inSameDayAs: now) },
            lastVisit: latest.date,
            recentWeeks: recent
        )
    }

    /// The first day of each week that contains one of the dates.
    func weekStarts(of dates: [Date]) -> Set<Date> {
        Set(dates.compactMap { calendar.dateInterval(of: .weekOfYear, for: $0)?.start })
    }

    /// Current and longest runs of consecutive weeks.
    func run(weeks: Set<Date>) -> (current: Int, longest: Int) {
        guard !weeks.isEmpty else { return (0, 0) }

        // The streak stays alive until the current week ends, so start from last week if this one is empty.
        var cursor = thisWeekStart
        if !weeks.contains(cursor) {
            cursor = week(offset: -1, from: cursor)
        }

        var current = 0
        while weeks.contains(cursor) {
            current += 1
            cursor = week(offset: -1, from: cursor)
        }

        var longest = 0
        var length = 0
        var previous: Date?
        for start in weeks.sorted() {
            if let previous, week(offset: 1, from: previous) == start {
                length += 1
            } else {
                length = 1
            }
            longest = max(longest, length)
            previous = start
        }

        return (current, longest)
    }

    private func week(offset: Int, from date: Date) -> Date {
        calendar.date(byAdding: .weekOfYear, value: offset, to: date) ?? date
    }
}
