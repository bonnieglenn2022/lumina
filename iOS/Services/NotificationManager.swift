import Foundation
import UserNotifications

/// Schedules each day's manifestation as a local notification.
/// iOS automatically mirrors these to a paired Apple Watch when the iPhone is locked,
/// and the "I receive this" action button appears on both devices.
final class NotificationManager {
    static let shared = NotificationManager()
    static let categoryID = "LUMINA_MANIFEST"
    static let affirmActionID = "LUMINA_AFFIRM"

    private let center = UNUserNotificationCenter.current()
    private let dailyPrefix = "lumina.daily."
    /// iOS allows 64 pending notifications: 6 reminders × 10 days = 60, plus the trial reminder.
    private let daysAhead = 10

    func registerCategories() {
        let affirm = UNNotificationAction(identifier: Self.affirmActionID,
                                          title: "I receive this ✨",
                                          options: [])
        let category = UNNotificationCategory(identifier: Self.categoryID,
                                              actions: [affirm],
                                              intentIdentifiers: [],
                                              options: [])
        center.setNotificationCategories([category])
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func reschedule(reminders: [Reminder], pool: [Affirmation], name: String, customSound: Bool = true) async {
        let existing = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(dailyPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: existing)

        guard !reminders.isEmpty, !pool.isEmpty else { return }
        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }

        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)

        for dayOffset in 0..<daysAhead {
            guard let day = cal.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }
            for (slot, reminder) in reminders.enumerated() {
                var comps = cal.dateComponents([.year, .month, .day], from: day)
                comps.hour = reminder.hour
                comps.minute = reminder.minute
                guard let fireDate = cal.date(from: comps), fireDate > now else { continue }

                let affirmation = DailyPicker.affirmation(for: day, slot: slot, pool: pool)
                let content = UNMutableNotificationContent()
                content.title = title(hour: reminder.hour, name: name)
                content.body = affirmation.text
                content.sound = customSound
                    ? UNNotificationSound(named: UNNotificationSoundName("lumina_chime.wav"))
                    : .default
                content.categoryIdentifier = Self.categoryID
                content.threadIdentifier = "lumina.daily"
                content.interruptionLevel = .active

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(identifier: "\(dailyPrefix)\(dayOffset).\(slot)",
                                                    content: content,
                                                    trigger: trigger)
                try? await center.add(request)
            }
        }
    }

    /// A courtesy heads-up 2 days before the free trial converts — builds trust and reduces refunds.
    func scheduleTrialEndingReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Your free trial ends in 2 days"
        content.body = "We hope Lumina is bringing you calm and clarity. You can manage your plan anytime in Settings."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 24 * 60 * 60, repeats: false)
        center.add(UNNotificationRequest(identifier: "lumina.trial.ending", content: content, trigger: trigger))
    }

    private func title(hour: Int, name: String) -> String {
        let suffix = name.isEmpty ? "" : ", \(name)"
        switch hour {
        case ..<12: return "Good morning\(suffix) ✨"
        case 12..<17: return "A moment for you\(suffix)"
        default: return "Evening reflection\(suffix)"
        }
    }
}
