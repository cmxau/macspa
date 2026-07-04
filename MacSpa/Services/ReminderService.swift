import Foundation
@preconcurrency import UserNotifications

/// Schedules the local "time to clean" reminder. All cadences fire on a Sunday
/// at 10:00 AM:
///   • weekly   - every Sunday
///   • biweekly - every alternate Sunday (from a fixed reference Sunday)
///   • monthly  - the first Sunday of each month
enum ReminderService {
    static let id = "macspa.reminder"
    private static let seriesCount = 8   // one-shots to pre-schedule for non-repeating cadences
    private static let hour = 10
    private static let minute = 0

    /// Fixed reference Sunday (2024-01-07 10:00) that defines the biweekly phase.
    private static var referenceSunday: Date {
        Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 7, hour: hour, minute: minute))
            ?? Date(timeIntervalSince1970: 0)
    }

    private static var allIDs: [String] { [id] + (0..<seriesCount).map { "\(id).\($0)" } }

    // MARK: Public

    /// Reads persisted settings and re-syncs the reminder. Called at launch so a
    /// scheduled reminder survives relaunches (and the one-shot series tops up).
    static func applyStored() {
        let d = UserDefaults.standard
        let enabled = d.object(forKey: "reminderEnabled") as? Bool ?? true
        let schedule = d.string(forKey: "reminderSchedule") ?? "monthly"
        apply(enabled: enabled, schedule: schedule)
    }

    /// Cancels any existing reminder and, if enabled, schedules a fresh one.
    /// Requests notification authorization the first time it's enabled.
    static func apply(enabled: Bool, schedule: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: allIDs)
        guard enabled else { return }

        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            // Use a fresh handle inside the @Sendable closure rather than capturing `center`.
            scheduleReminder(schedule, center: .current())
        }
    }

    /// The next time the reminder will fire, or nil if reminders are off.
    static func nextDate() -> Date? {
        let d = UserDefaults.standard
        guard d.object(forKey: "reminderEnabled") as? Bool ?? true else { return nil }
        switch d.string(forKey: "reminderSchedule") ?? "monthly" {
        case "weekly":   return nextWeeklySunday(after: Date())
        case "biweekly": return nextBiweeklySunday(after: Date())
        default:         return nextFirstSunday(after: Date())   // monthly
        }
    }

    // MARK: Sunday math

    /// The next Sunday at 10:00 strictly after `date`.
    private static func nextWeeklySunday(after date: Date) -> Date? {
        var c = DateComponents(); c.weekday = 1; c.hour = hour; c.minute = minute
        return Calendar.current.nextDate(after: date, matching: c, matchingPolicy: .nextTime)
    }

    /// The next alternate Sunday at 10:00 after `date`, phased to `referenceSunday`.
    private static func nextBiweeklySunday(after date: Date) -> Date {
        let cal = Calendar.current
        var next = referenceSunday
        // Jump forward in 14-day strides until past `date`.
        let stride: TimeInterval = 14 * 86_400
        if next <= date {
            let k = (date.timeIntervalSince(next) / stride).rounded(.down) + 1
            next = next.addingTimeInterval(k * stride)
        }
        while next <= date { next = cal.date(byAdding: .day, value: 14, to: next) ?? next.addingTimeInterval(stride) }
        return next
    }

    /// The first Sunday (at 10:00) of a month, on or after `date`.
    private static func nextFirstSunday(after date: Date) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: date)
        for _ in 0..<24 {
            if let fs = firstSunday(year: comps.year!, month: comps.month!), fs > date { return fs }
            // advance one month
            comps.month! += 1
            if comps.month! > 12 { comps.month = 1; comps.year! += 1 }
        }
        return date.addingTimeInterval(30 * 86_400)
    }

    private static func firstSunday(year: Int, month: Int) -> Date? {
        let cal = Calendar.current
        guard let first = cal.date(from: DateComponents(year: year, month: month, day: 1, hour: hour, minute: minute))
        else { return nil }
        let weekday = cal.component(.weekday, from: first)   // 1 = Sunday
        let add = (8 - weekday) % 7                          // 0 if already Sunday
        return cal.date(byAdding: .day, value: add, to: first)
    }

    // MARK: Scheduling

    private static func content() -> UNMutableNotificationContent {
        let c = UNMutableNotificationContent()
        c.title = "Time for a spa day"
        c.body = "Your Mac could use a gentle clean."
        c.sound = .default
        return c
    }

    private static func scheduleReminder(_ cadence: String, center: UNUserNotificationCenter) {
        let cal = Calendar.current
        switch cadence {
        case "weekly":
            // A single repeating trigger: every Sunday at 10:00.
            var c = DateComponents(); c.weekday = 1; c.hour = hour; c.minute = minute
            add(id, dateMatching: c, repeats: true, center: center)

        case "biweekly":
            // Alternate Sundays can't be expressed as one repeating trigger; pre-schedule a series.
            var fire = nextBiweeklySunday(after: Date())
            for i in 0..<seriesCount {
                let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
                add("\(id).\(i)", dateMatching: comps, repeats: false, center: center)
                fire = cal.date(byAdding: .day, value: 14, to: fire) ?? fire.addingTimeInterval(14 * 86_400)
            }

        default: // "monthly" - first Sunday of each month; pre-schedule a series.
            var fire = nextFirstSunday(after: Date())
            for i in 0..<seriesCount {
                let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
                add("\(id).\(i)", dateMatching: comps, repeats: false, center: center)
                fire = nextFirstSunday(after: fire)
            }
        }
    }

    private static func add(_ identifier: String, dateMatching comps: DateComponents,
                            repeats: Bool, center: UNUserNotificationCenter) {
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: repeats)
        center.add(UNNotificationRequest(identifier: identifier, content: content(), trigger: trigger))
    }
}
