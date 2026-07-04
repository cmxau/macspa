import Foundation
import SwiftData

/// SwiftData-backed preferences record. Currently the app reads/writes settings
/// via `@AppStorage`; this model is registered in the schema for future use.
@Model
final class UserPreferences {
    var hasCompletedOnboarding: Bool
    var unlockKeyCode: Int         // CGKeyCode for K = 40
    var safetyTimeoutSeconds: Int  // 0 = disabled
    var reminderSchedule: String   // "weekly" | "biweekly" | "monthly" | "custom"
    var reminderEnabled: Bool
    var launchAtLogin: Bool
    var showMoodInMenuBar: Bool

    init() {
        self.hasCompletedOnboarding = false
        self.unlockKeyCode = 40
        self.safetyTimeoutSeconds = 180
        self.reminderSchedule = "monthly"
        self.reminderEnabled = true
        self.launchAtLogin = false
        self.showMoodInMenuBar = false
    }
}
