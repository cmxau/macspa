import SwiftUI
import AppKit

/// App lifecycle hooks: applies the saved theme, re-schedules reminders, and
/// renders the vector brand mark as the dock icon.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppTheme.applyStored()
        ReminderService.applyStored()
        setDockIcon()
        // Bring the main window to the front so launching is obvious.
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Re-open the window when the dock icon is clicked and no window is visible.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { NSApp.windows.first?.makeKeyAndOrderFront(nil) }
        return true
    }

    /// Renders the vector AppLogo to the dock icon (the menu-bar item keeps its own glyph).
    /// The mark sits inside a transparent margin so it matches Apple's icon grid
    /// (~80% content) instead of bleeding to the edges and looking oversized.
    @MainActor private func setDockIcon() {
        let icon = AppLogo()
            .frame(width: 412, height: 412)
            .frame(width: 512, height: 512)   // centered with transparent padding
        let renderer = ImageRenderer(content: icon)
        renderer.scale = 2
        if let img = renderer.nsImage {
            NSApplication.shared.applicationIconImage = img
        }
    }
}
