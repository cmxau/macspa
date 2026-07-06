// SessionWindowController.swift
import AppKit
import SwiftUI
import SwiftData

@MainActor
final class SessionWindowController {
    static let shared = SessionWindowController()
    private var windows: [NSWindow] = []
    private weak var trackedAppState: AppState?

    private init() {}

    /// `startKind` runs a single-device ritual (from Guided Cleaning); nil runs the
    /// full keyboard → trackpad → display session (from "Begin Spa").
    func show(appState: AppState, eventTap: EventTapService, container: ModelContainer, startKind: DeviceKind? = nil) {
        close()
        trackedAppState = appState
        appState.isSessionActive = true
        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
            window.isOpaque = false
            window.backgroundColor = .clear
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let isPrimary = screen == NSScreen.main
            window.contentView = NSHostingView(
                rootView: ZStack {
                    VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                        .ignoresSafeArea()
                    if isPrimary {
                        SessionView(onlyKind: startKind, onEnd: { Task { @MainActor in self.close() } })
                            .environment(appState)
                            .environment(eventTap)
                            .modelContainer(container)
                    }
                }
                .frame(width: screen.frame.width, height: screen.frame.height)
            )
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }
    }

    func close() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        trackedAppState?.isSessionActive = false
        trackedAppState = nil
    }
}

// MARK: - Visual Effect Bridge

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
