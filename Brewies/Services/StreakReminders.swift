//
//  StreakReminders.swift
//  Brewies
//
//  An optional nudge, at most once a week, when a streak is about to lapse.
//

import UserNotifications

enum StreakReminders {
    private static let identifier = "brewies.streak.reminder"

    /// Asks the user for permission to send reminders. Returns whether it was granted.
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Replaces any pending reminder with one for the streak most worth saving, or none.
    static func update(summary: StreakSummary, enabled: Bool, now: Date = Date(), calendar: Calendar = .current) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard enabled,
              let streak = summary.shops.first(where: { $0.isAtRisk && $0.current >= 2 }),
              let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return }

        // A day and a half before the week ends. If that has passed, remind in an hour, unless the week is nearly over.
        var fireDate = week.end.addingTimeInterval(-36 * 3600)
        if fireDate <= now {
            fireDate = now.addingTimeInterval(3600)
        }
        guard fireDate < week.end.addingTimeInterval(-3 * 3600) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Keep your streak going"
        content.body = "You're \(streak.current) weeks in at \(streak.shop.name). Stop by before the week ends."
        content.sound = .default

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
}
