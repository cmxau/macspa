import Foundation

/// Per-device cleaning durations, in seconds. Stored in `@AppStorage` under
/// "durKeyboard" / "durTrackpad" / "durDisplay"; users set them in Settings and
/// the session + guided cards follow those values, falling back to these defaults.
enum CleaningDurations {
    static let defaultKeyboard = 30
    static let defaultTrackpad = 15
    static let defaultDisplay  = 45

    /// Allowed range a user can set (seconds).
    static let range = 10...180
    static let step = 5

    /// Compact label: "45s", "1 min", or "1m 30s".
    static func label(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        return seconds % 60 == 0 ? "\(seconds / 60) min" : "\(seconds / 60)m \(seconds % 60)s"
    }
}
