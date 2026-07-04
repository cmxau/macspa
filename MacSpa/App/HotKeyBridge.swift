import SwiftUI
import SwiftData
import AppKit

/// Invisible view that wires the global hot-key actions (they need SwiftUI's
/// `openWindow` plus the environment services) and registers them once on appear.
struct HotKeyBridge: View {
    let hotKeys: HotKeyService
    let appState: AppState
    let eventTap: EventTapService
    let container: ModelContainer
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear.onAppear {
            hotKeys.onStartSpa = {
                SessionWindowController.shared.show(appState: appState, eventTap: eventTap, container: container)
            }
            hotKeys.onOpenDashboard = {
                appState.selectedTab = .dashboard
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            // Session unlock combo drives the event tap.
            let unlock = HotKeyStore.load(.unlock)
            eventTap.unlockKeyCode = CGKeyCode(unlock.keyCode)
            eventTap.unlockModifiers = unlock.cgFlags
            hotKeys.reloadFromDefaults()
        }
    }
}
