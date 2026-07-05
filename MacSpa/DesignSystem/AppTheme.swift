import AppKit

/// Applies the user's Theme setting ("light" | "dark" | "auto") by driving the
/// process-wide `NSApp.appearance`. Setting it to `nil` for "auto" lets every
/// window follow the system appearance. Covers all windows - main, menu bar
/// popover, and the session overlay - from one place.
@MainActor
enum AppTheme {
    static func apply(_ raw: String) {
        let appearance: NSAppearance?
        switch raw {
        case "light": appearance = NSAppearance(named: .aqua)
        case "dark":  appearance = NSAppearance(named: .darkAqua)
        default:      appearance = nil   // auto → follow system
        }
        NSApplication.shared.appearance = appearance
    }

    /// Reads the persisted theme setting and applies it. Safe to call at launch.
    static func applyStored() {
        apply(UserDefaults.standard.string(forKey: "theme") ?? "auto")
    }
}
