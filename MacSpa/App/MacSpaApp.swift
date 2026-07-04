import SwiftUI
import SwiftData

@main
struct MacSpaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState = AppState()
    @State private var eventTap = EventTapService()
    @State private var hotKeys = HotKeyService()
    @AppStorage("showMoodInMenuBar") private var showMoodInMenuBar = false

    var modelContainer: ModelContainer = {
        let schema = Schema([CleaningSession.self, Achievement.self, UserPreferences.self])
        let config = ModelConfiguration(schema: schema)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        // Real macOS menu bar icon + popover
        MenuBarExtra {
            MenuBarPopoverView()
                .environment(appState)
                .environment(eventTap)
                .environment(hotKeys)
                .modelContainer(modelContainer)
                .background(HotKeyBridge(hotKeys: hotKeys, appState: appState, eventTap: eventTap, container: modelContainer))
        } label: {
            if showMoodInMenuBar {
                // Mood symbol beside the icon; updates live as wellness changes.
                Image(systemName: appState.mood.symbol)
            } else {
                Label("MacSpa", systemImage: appState.isSessionActive ? "sparkles" : "sparkle")
            }
        }
        .menuBarExtraStyle(.window)

        // Main app window (opened from menu bar or dock)
        Window("MacSpa", id: "main") {
            Group {
                if appState.showOnboarding {
                    OnboardingView()
                } else {
                    AppWindowView()
                }
            }
            .environment(appState)
            .environment(eventTap)
            .environment(hotKeys)
            .modelContainer(modelContainer)
            .background(HotKeyBridge(hotKeys: hotKeys, appState: appState, eventTap: eventTap, container: modelContainer))
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1240, height: 760)
        .windowResizability(.contentMinSize)
    }
}
