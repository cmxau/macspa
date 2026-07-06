import SwiftUI
import AppKit

enum SettingsSection: String, CaseIterable, Identifiable {
    case general, cleaning, shortcuts, about
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .general: "gearshape"; case .cleaning: "wind"
        case .shortcuts: "command"; case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selected: SettingsSection = .general
    @State private var showPurgeConfirm = false
    @AppStorage("theme") private var theme = "auto"
    @AppStorage("storeHistory") private var storeHistory = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMoodInMenuBar") private var showMoodInMenuBar = false
    @AppStorage("safetyTimeout") private var safetyTimeout = "3m"
    @AppStorage("customSafetySeconds") private var customSafetySeconds = 240
    @AppStorage("chimeOnCompletion") private var chimeOnCompletion = true
    @AppStorage("cleaningSounds") private var cleaningSounds = true
    @AppStorage("soundKeyboard") private var soundKeyboard = true
    @AppStorage("soundTrackpad") private var soundTrackpad = true
    @AppStorage("soundDisplay") private var soundDisplay = true

    var body: some View {
        HStack(spacing: 0) {
            // Settings sidebar
            List(SettingsSection.allCases, selection: $selected) { section in
                Label(section.label, systemImage: section.icon).tag(section)
            }
            .listStyle(.sidebar)
            .frame(width: 200)

            Divider()

            // Settings detail
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 12) {
                        IconTile(systemName: selected.icon, color: .spaPrimary, size: 38, symbolSize: 17)
                        Text(selected.label).font(.title2.weight(.bold))
                    }
                    .padding(.bottom, 4)

                    switch selected {
                    case .general:
                        SettingsGroupHeader("Appearance")
                        SettingsRow("Theme", hint: "Match your macOS setting or pick your own.") {
                            Picker("", selection: $theme) {
                                Label("Light", systemImage: "sun.max").tag("light")
                                Label("Dark", systemImage: "moon").tag("dark")
                                Label("Auto", systemImage: "circle.lefthalf.filled").tag("auto")
                            }
                            .pickerStyle(.segmented).frame(width: 200)
                            .onChange(of: theme) { _, newValue in AppTheme.apply(newValue) }
                        }
                        SettingsRow("Accent", hint: "The brand color used across the app.") {
                            AccentPickerRow()
                        }

                        SettingsGroupHeader("Menu Bar & Startup")
                        SettingsRow("Launch at login", hint: "Open MacSpa automatically when you sign in.") {
                            Toggle("", isOn: $launchAtLogin)
                                .toggleStyle(.switch)
                                .onChange(of: launchAtLogin) { _, newValue in
                                    // Reconcile with the actual login-item state; the OS may reject the change.
                                    launchAtLogin = LoginItemService.setEnabled(newValue)
                                }
                        }
                        SettingsRow("Show mood in menu bar", hint: "Show your Mac\u{2019}s mood emoji beside the menu bar icon.") {
                            Toggle("", isOn: $showMoodInMenuBar).toggleStyle(.switch)
                        }

                        SettingsGroupHeader("Motion & Access")
                        AccessibilitySection()

                    case .cleaning:
                        SettingsGroupHeader("Session")
                        SettingsRow("Safety timeout", hint: "Auto-end a session after this much time, as a safety cap.") {
                            Picker("", selection: $safetyTimeout) {
                                Text("2 minutes").tag("2m")
                                Text("3 minutes").tag("3m")
                                Text("Custom").tag("custom")
                            }.frame(width: 160)
                        }
                        if safetyTimeout == "custom" {
                            SettingsRow("Custom timeout", hint: "Your own safety cap (a full ritual is about 1:30).") {
                                HStack(spacing: 12) {
                                    Text(CleaningDurations.label(customSafetySeconds))
                                        .font(.subheadline.weight(.semibold)).monospacedDigit()
                                        .frame(minWidth: 62, alignment: .trailing)
                                    Stepper("", value: $customSafetySeconds, in: 60...900, step: 30)
                                        .labelsHidden()
                                }
                            }
                        }
                        SettingsRow("Play chime on completion", hint: "A soft bell when a session finishes.") {
                            HStack(spacing: 10) {
                                if chimeOnCompletion { SoundPreviewButton(cue: .completion) }
                                Toggle("", isOn: $chimeOnCompletion).toggleStyle(.switch)
                            }
                        }

                        SettingsGroupHeader("Stage Durations")
                        DurationsSection()

                        SettingsGroupHeader("Cleaning Sounds")
                        SettingsRow("Cleaning sounds", hint: "Gentle cue as each device stage begins.") {
                            Toggle("", isOn: $cleaningSounds).toggleStyle(.switch)
                        }
                        if cleaningSounds {
                            SoundToggleRow(label: "Keyboard sound", cue: .keyboard, isOn: $soundKeyboard)
                            SoundToggleRow(label: "Trackpad sound", cue: .trackpad, isOn: $soundTrackpad)
                            SoundToggleRow(label: "Display sound",  cue: .display,  isOn: $soundDisplay)
                        }

                        SettingsGroupHeader("Reminders")
                        RemindersSection()

                        SettingsGroupHeader("Data & Privacy")
                        SettingsRow("Store history locally", hint: "Keep your cleaning sessions saved on this Mac.") {
                            Toggle("", isOn: $storeHistory)
                                .toggleStyle(.switch)
                                .onChange(of: storeHistory) { _, on in
                                    if !on { showPurgeConfirm = true }
                                }
                        }
                        SettingsRow("Export data", hint: "Save your cleaning data as a JSON file on this Mac.") {
                            Button("Export…") { DataExportService.run(context: modelContext) }
                                .buttonStyle(.bordered)
                        }

                    case .shortcuts:
                        ShortcutRecorderRow(id: .startSpa)
                        ShortcutRecorderRow(id: .unlock)
                        ShortcutRecorderRow(id: .openDashboard)

                    case .about:
                        AboutSection()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(32)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))   // native prefs surface, not the app aurora
        .onAppear {
            // Trust the system as source of truth for the login item.
            launchAtLogin = LoginItemService.isEnabled
        }
        .confirmationDialog("Delete stored history?", isPresented: $showPurgeConfirm, titleVisibility: .visible) {
            Button("Delete All Data", role: .destructive) {
                DataExportService.purgeAll(context: modelContext)
            }
            Button("Keep Data", role: .cancel) { }
        } message: {
            Text("This permanently removes all cleaning sessions and achievements from this Mac. This can\u{2019}t be undone.")
        }
    }
}

private struct SettingsRow<Content: View>: View {
    let label: String; let hint: String?
    @ViewBuilder let content: Content
    init(_ label: String, hint: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label; self.hint = hint; self.content = content()
    }
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.body.weight(.medium))
                if let hint { Text(hint).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer()
            content
        }
        .padding(.vertical, 6)
        Divider().opacity(0.4)
    }
}

/// Reminders settings: enable, schedule cadence, and exact timing controls.
/// Every change re-syncs the pending local notification via ReminderService.
private struct RemindersSection: View {
    @AppStorage("reminderEnabled") private var enabled = true
    @AppStorage("reminderSchedule") private var schedule = "monthly"

    var body: some View {
        SettingsRow("Gentle notifications", hint: "An occasional nudge to run a spa session.") {
            Toggle("", isOn: $enabled).toggleStyle(.switch)
                .onChange(of: enabled) { _, _ in reschedule() }
        }
        SettingsRow("Schedule", hint: scheduleHint) {
            Picker("", selection: $schedule) {
                Text("Weekly").tag("weekly")
                Text("Bi-weekly").tag("biweekly")
                Text("Monthly").tag("monthly")
            }
            .frame(width: 160)
            .disabled(!enabled)
            .onChange(of: schedule) { _, _ in reschedule() }
        }
    }

    private var scheduleHint: String {
        switch schedule {
        case "weekly":   return "Every Sunday at 10:00 AM."
        case "biweekly": return "Every alternate Sunday at 10:00 AM."
        default:         return "First Sunday of each month at 10:00 AM."
        }
    }

    private func reschedule() {
        ReminderService.apply(enabled: enabled, schedule: schedule)
    }
}

/// Row of accent color swatches; selecting one restyles the whole app live.
private struct AccentPickerRow: View {
    @AppStorage("accentColor") private var accentColor = "blue"

    var body: some View {
        HStack(spacing: 10) {
            ForEach(SpaAccent.allCases) { accent in
                let selected = accent.rawValue == accentColor
                Button { accentColor = accent.rawValue } label: {
                    Circle()
                        .fill(accent.base)
                        .frame(width: 22, height: 22)
                        .overlay(Circle().stroke(Color.primary.opacity(selected ? 0.9 : 0), lineWidth: 2).padding(-3))
                        .overlay(Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                            .opacity(selected ? 1 : 0))
                }
                .buttonStyle(.plain)
                .help(accent.label)
            }
        }
    }
}

/// Per-device stage durations. Each session/guided ritual follows these values.
private struct DurationsSection: View {
    @AppStorage("durKeyboard") private var durKeyboard = CleaningDurations.defaultKeyboard
    @AppStorage("durTrackpad") private var durTrackpad = CleaningDurations.defaultTrackpad
    @AppStorage("durDisplay")  private var durDisplay  = CleaningDurations.defaultDisplay

    private var isDefault: Bool {
        durKeyboard == CleaningDurations.defaultKeyboard &&
        durTrackpad == CleaningDurations.defaultTrackpad &&
        durDisplay  == CleaningDurations.defaultDisplay
    }

    var body: some View {
        durationRow("Keyboard", value: $durKeyboard)
        durationRow("Trackpad", value: $durTrackpad)
        durationRow("Display",  value: $durDisplay)
        SettingsRow("Reset to defaults",
                    hint: "\(CleaningDurations.label(CleaningDurations.defaultKeyboard)) · \(CleaningDurations.label(CleaningDurations.defaultTrackpad)) · \(CleaningDurations.label(CleaningDurations.defaultDisplay)).") {
            Button("Reset") {
                durKeyboard = CleaningDurations.defaultKeyboard
                durTrackpad = CleaningDurations.defaultTrackpad
                durDisplay  = CleaningDurations.defaultDisplay
            }
            .buttonStyle(.bordered)
            .disabled(isDefault)
        }
    }

    private func durationRow(_ label: String, value: Binding<Int>) -> some View {
        SettingsRow(label, hint: "How long this stage runs.") {
            HStack(spacing: 12) {
                Text(CleaningDurations.label(value.wrappedValue))
                    .font(.subheadline.weight(.semibold)).monospacedDigit()
                    .frame(minWidth: 62, alignment: .trailing)
                Stepper("", value: value, in: CleaningDurations.range, step: CleaningDurations.step)
                    .labelsHidden()
            }
        }
    }
}

/// A per-device cleaning-sound row: preview button + individual on/off toggle.
private struct SoundToggleRow: View {
    let label: String
    let cue: SoundService.Cue
    @Binding var isOn: Bool
    var body: some View {
        SettingsRow(label, hint: "System sound: \u{201C}\(cue.rawValue)\u{201D}") {
            HStack(spacing: 10) {
                if isOn { SoundPreviewButton(cue: cue) }
                Toggle("", isOn: $isOn).toggleStyle(.switch)
            }
        }
        .padding(.leading, 20)
    }
}

/// Small speaker button that previews a cue on click.
private struct SoundPreviewButton: View {
    let cue: SoundService.Cue
    var body: some View {
        Button { cue == .completion ? SoundService.playFinale() : SoundService.play(cue) } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.caption)
                .foregroundStyle(Color.spaPrimary)
        }
        .buttonStyle(.plain)
        .help("Preview")
    }
}

/// Small uppercase divider label to group settings within a merged section.
private struct SettingsGroupHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title.uppercased())
            .font(.caption2.weight(.semibold)).tracking(0.8)
            .foregroundStyle(Color.spaPrimary)
            .padding(.top, 14).padding(.bottom, 2)
    }
}

// MARK: - Accessibility

private struct AccessibilitySection: View {
    @AppStorage("reducedMotion") private var reducedMotion = false
    @State private var trusted = AXIsProcessTrusted()
    // Poll while visible so a grant made in System Settings reflects without a restart.
    private let poll = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        SettingsRow("Reduced motion", hint: "Minimize animations and motion effects throughout the app.") {
            Toggle("", isOn: $reducedMotion).toggleStyle(.switch)
        }
        SettingsRow("Accessibility permission", hint: "Required for safe cleaning mode.") {
            HStack(spacing: 10) {
                Label(trusted ? "Granted" : "Not granted",
                      systemImage: trusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(trusted ? Color.spaSuccess : Color.spaWarning)
                    .font(.subheadline.weight(.medium))
                if trusted {
                    Button("Re-check") { trusted = AXIsProcessTrusted() }
                        .buttonStyle(.bordered).controlSize(.small)
                } else {
                    Button("Grant…") { requestAccess() }
                        .buttonStyle(.borderedProminent).tint(Color.spaPrimary).controlSize(.small)
                }
            }
            .onAppear { trusted = AXIsProcessTrusted() }
            // Re-check when the app regains focus (user returns from System Settings)…
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                trusted = AXIsProcessTrusted()
            }
            // …and while the pane stays open.
            .onReceive(poll) { _ in
                let now = AXIsProcessTrusted()
                if now != trusted { trusted = now }
            }
        }
    }

    private func requestAccess() {
        // Prompt, then open the pane so the user can flip the switch.
        let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - About

private struct AboutSection: View {
    @Environment(AppState.self) private var appState
    private var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
    private var build: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1" }

    var body: some View {
        VStack(spacing: 16) {
            AppLogo()
                .frame(width: 72, height: 72)
            VStack(spacing: 4) {
                Text("MacSpa").font(.title2.weight(.bold))
                Text("Version \(version) (build \(build))").font(.subheadline).foregroundStyle(.secondary)
            }
            Text("A calm menu-bar companion for caring for your Mac - guided cleaning that safely pauses input, plus a real read on your Mac\u{2019}s health. Everything stays on this device.")
                .font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).frame(maxWidth: 440)

            GroupBox {
                VStack(spacing: 0) {
                    SupportRow(icon: "ladybug",
                               title: "Report a Bug",
                               subtitle: "Something not working right? Let us know.",
                               button: "Submit") { open(SupportLinks.bugReport()) }
                    Divider().padding(.leading, 44)
                    SupportRow(icon: "lightbulb",
                               title: "Request a Feature",
                               subtitle: "Have an idea to make MacSpa better?",
                               button: "Submit") { open(SupportLinks.featureRequest()) }
                }
            } label: {
                Label("Feedback", systemImage: "bubble.left.and.text.bubble.right.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: 440)
            .padding(.top, 8)

            Button {
                appState.showOnboarding = true
            } label: {
                Label("View onboarding again", systemImage: "sparkles.rectangle.stack")
            }
            .buttonStyle(.bordered)
            .padding(.top, 2)

            Spacer(minLength: 40)

            // Attribution pinned to the very bottom.
            VStack(spacing: 6) {
                Text("Acknowledgements")
                    .font(.subheadline.weight(.semibold))
                Text("Apple, the Apple logo, macOS, and SF Symbols are trademarks of Apple Inc., registered in the U.S. and other countries. The Apple logo shown in-app is Apple\u{2019}s SF Symbol, used under the SF Symbols license for identification purposes only. MacSpa is not affiliated with, endorsed by, or sponsored by Apple Inc.")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 440)
        }
        .frame(maxWidth: .infinity, minHeight: 500, alignment: .top)
        .padding(.top, 28)
    }

    private func open(_ url: URL?) { if let url { NSWorkspace.shared.open(url) } }
}

/// A native-styled feedback row: tinted glyph, title/subtitle, and a bordered action button.
private struct SupportRow: View {
    let icon: String
    let title: String; let subtitle: String
    let button: String; let action: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .center)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.body.weight(.medium))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(button, action: action).buttonStyle(.bordered).controlSize(.regular)
        }
        .padding(.vertical, 8)
    }
}

/// GitHub + support links, with preloaded issue templates.
private enum SupportLinks {
    static let repo = "https://github.com/cmxau/macspa"

    static func bugReport() -> URL? { issue(title: "Bug: ", body: bugBody) }
    static func featureRequest() -> URL? { issue(title: "Feature request: ", body: featureBody) }

    private static func issue(title: String, body: String) -> URL? {
        var c = URLComponents(string: "\(repo)/issues/new")
        c?.queryItems = [URLQueryItem(name: "title", value: title),
                         URLQueryItem(name: "body", value: body)]
        return c?.url
    }

    private static var env: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "- MacSpa version: \(v)\n- macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)"
    }
    private static var bugBody: String {
        """
        **Describe the bug**
        A clear description of what went wrong.

        **Steps to reproduce**
        1.
        2.

        **Expected behavior**


        **Environment**
        \(env)
        """
    }
    private static var featureBody: String {
        """
        **What would you like MacSpa to do?**


        **Why is this valuable?**


        **Additional context**

        """
    }
}

/// A rebindable shortcut row: shows the current combo, records a new one on
/// click, and resets to default. Applies changes immediately.
private struct ShortcutRecorderRow: View {
    let id: ShortcutID
    @Environment(HotKeyService.self) private var hotKeys
    @Environment(EventTapService.self) private var eventTap
    @State private var current: HotKey
    @State private var recording = false
    @State private var monitor: Any?

    // Modifier-only key codes to ignore while recording.
    private static let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62]

    init(id: ShortcutID) {
        self.id = id
        _current = State(initialValue: HotKeyStore.load(id))
    }

    var body: some View {
        SettingsRow(id.label, hint: recording ? "Press a key combination…" : nil) {
            HStack(spacing: 8) {
                if recording {
                    Text("Press keys…")
                        .font(.caption.weight(.medium)).foregroundStyle(Color.spaPrimary)
                        .frame(minWidth: 90, minHeight: 22)
                } else {
                    HStack(spacing: 4) {
                        ForEach(Array(current.keyCaps.enumerated()), id: \.offset) { _, cap in
                            Text(cap).font(.system(.caption, design: .monospaced).weight(.medium))
                                .frame(minWidth: 22, minHeight: 22).padding(.horizontal, 4)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                                .overlay(RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                        }
                    }
                }
                Button(recording ? "Cancel" : "Change") { recording ? stop() : start() }
                    .buttonStyle(.bordered).controlSize(.small)
                Button { apply(id.default) } label: { Image(systemName: "arrow.uturn.backward") }
                    .buttonStyle(.borderless).controlSize(.small).help("Reset to default")
            }
        }
    }

    private func start() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if Self.modifierKeyCodes.contains(event.keyCode) { return nil } // wait for real key
            let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
            apply(HotKey(keyCode: UInt32(event.keyCode), modifiers: mods.rawValue))
            stop()
            return nil // swallow the recorded combo
        }
    }

    private func stop() {
        recording = false
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }

    private func apply(_ hk: HotKey) {
        current = hk
        HotKeyStore.save(id, hk)
        if id == .unlock {
            eventTap.unlockKeyCode = CGKeyCode(hk.keyCode)
            eventTap.unlockModifiers = hk.cgFlags
        } else {
            hotKeys.reloadFromDefaults()
        }
    }
}
