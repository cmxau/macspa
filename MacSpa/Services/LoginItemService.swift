import Foundation
import ServiceManagement

/// Wraps `SMAppService.mainApp` to toggle the app's "Launch at login" login item.
/// macOS 13+ API; MacSpa targets macOS 15 so no availability guard is needed.
enum LoginItemService {
    /// True when the main app is currently registered as a login item.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Registers or unregisters the login item. Returns the resulting enabled state,
    /// which may differ from `enabled` if the OS rejected the change (e.g. the user
    /// disabled it in System Settings > General > Login Items).
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("LoginItemService: failed to set launch-at-login=\(enabled): \(error.localizedDescription)")
        }
        return isEnabled
    }
}
