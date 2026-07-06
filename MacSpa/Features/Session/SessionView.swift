import SwiftUI
import SwiftData
import AppKit

struct SessionView: View {
    @Environment(AppState.self) private var appState
    @Environment(EventTapService.self) private var eventTap
    @Environment(\.modelContext) private var modelContext
    /// When set, runs a single-device ritual instead of the full three-stage session.
    var onlyKind: DeviceKind? = nil
    var onEnd: () -> Void = {}

    @AppStorage("safetyTimeout") private var safetyTimeout = "3m"
    @AppStorage("customSafetySeconds") private var customSafetySeconds = 240
    @AppStorage("chimeOnCompletion") private var chimeOnCompletion = true
    @AppStorage("cleaningSounds") private var cleaningSounds = true
    @AppStorage("soundKeyboard") private var soundKeyboard = true
    @AppStorage("soundTrackpad") private var soundTrackpad = true
    @AppStorage("soundDisplay") private var soundDisplay = true
    @AppStorage("storeHistory") private var storeHistory = true
    // Per-device durations (seconds). User-set in Settings; defaults 30 / 15 / 45.
    @AppStorage("durKeyboard") private var durKeyboard = CleaningDurations.defaultKeyboard
    @AppStorage("durTrackpad") private var durTrackpad = CleaningDurations.defaultTrackpad
    @AppStorage("durDisplay")  private var durDisplay  = CleaningDurations.defaultDisplay

    private typealias Stage = (icon: String, title: String, instruction: String, tip: String, duration: Double, category: QuipCategory)

    private var allStages: [Stage] {
        [
            ("keyboard", "Keyboard Care",
             "Use a clean microfiber cloth. Move gently in circular motions.",
             "Tilt your Mac slightly so crumbs slide out - no compressed air needed.", Double(durKeyboard), .keyboard),
            ("square.fill", "Trackpad Polish",
             "Lightly buff the trackpad. A dry cloth is plenty.",
             "Avoid solvents. A soft dry pass restores that new-Mac glide.", Double(durTrackpad), .trackpad),
            ("display", "Display Refresh",
             "Wipe top to bottom in slow, straight passes.",
             "Never spray directly. Barely-damp is the sweet spot.", Double(durDisplay), .display),
        ]
    }

    /// The stages this session runs: a single device when `onlyKind` is set,
    /// otherwise the full keyboard → trackpad → display ritual.
    private var stages: [Stage] {
        guard let onlyKind else { return allStages }
        return allStages.filter { stageKind(for: $0.category) == onlyKind }
    }

    @State private var stageIndex = 0
    @State private var elapsed: Double = 0
    @State private var totalElapsed: Double = 0
    @State private var currentQuip: String = ""
    @State private var sessionTimer: Timer?
    @State private var quipTimer: Timer?
    @State private var overlayClickCount = 0
    @State private var blockSeconds = 0

    private let personality = PersonalityService()

    private var stage: (icon: String, title: String, instruction: String, tip: String, duration: Double, category: QuipCategory) {
        stages[stageIndex]
    }

    private func stageKind(for category: QuipCategory) -> DeviceKind {
        switch category {
        case .keyboard: return .keyboard
        case .trackpad: return .trackpad
        case .display:  return .display
        case .completion: return .keyboard
        }
    }

    private var stageKind: DeviceKind { stageKind(for: stage.category) }

    /// Which device to lock for the current stage. Display cleaning locks both,
    /// since your hands are on the screen and neither input should register.
    private var stageLock: LockMode {
        switch stage.category {
        case .keyboard: return .keyboard
        case .trackpad: return .trackpad
        case .display:  return .both
        case .completion: return .keyboard
        }
    }

    private var progress: Double { min(1, elapsed / stage.duration) }
    private var remaining: Double { max(0, stage.duration - elapsed) }
    private var timeDisplay: String {
        let s = Int(remaining.rounded(.up)); return String(format: "%02d:%02d", s / 60, s % 60)
    }

    /// Safety-timeout setting mapped to seconds (2 min / 3 min / custom).
    private var safetyTimeoutSeconds: Int {
        switch safetyTimeout {
        case "2m":     return 120
        case "custom": return max(60, customSafetySeconds)
        default:       return 180   // "3m"
        }
    }

    /// Plays the current stage's cue if cleaning sounds and that device are enabled.
    private func playStageSound() {
        guard cleaningSounds else { return }
        switch stage.category {
        case .keyboard: if soundKeyboard { SoundService.play(.keyboard) }
        case .trackpad: if soundTrackpad { SoundService.play(.trackpad) }
        case .display:  if soundDisplay  { SoundService.play(.display) }
        case .completion: break
        }
    }

    var body: some View {
        ZStack {
            Color.spaCanvas.ignoresSafeArea()
            RadialGradient(colors: [Color.spaPrimary.opacity(0.22), .clear],
                           center: .top, startRadius: 0, endRadius: 620)
                .ignoresSafeArea()
            RadialGradient(colors: [Color.spaPrimaryDeep.opacity(0.16), .clear],
                           center: .bottomTrailing, startRadius: 0, endRadius: 560)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Safe mode badge - honest about whether input is actually locked.
                HStack {
                    Spacer()
                    // Strong material (not light glass) so nothing translucent stacks
                    // on the visual-effect base, plus a shadow for separation.
                    if eventTap.isBlocking {
                        Label("Safe Cleaning Mode Active", systemImage: "lock.fill")
                            .font(.caption.weight(.medium)).foregroundStyle(Color.spaSuccess)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .glassStrong(cornerRadius: 20)
                            .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
                    } else {
                        Button { openAccessibilitySettings() } label: {
                            Label("Input not locked - grant Accessibility", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.weight(.semibold)).foregroundStyle(Color.spaWarning)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .glassStrong(cornerRadius: 20)
                                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.top, 40)
                .overlay(alignment: .topTrailing) {
                    Button { endSession() } label: {
                        Image(systemName: "xmark")
                            .frame(width: 36, height: 36)
                            .glassStrong(cornerRadius: 18)
                            .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 32).padding(.top, 32)
                }

                Spacer()

                // Stage title
                VStack(spacing: 8) {
                    Label("Step \(stageIndex + 1) of \(stages.count) · \(stage.title)",
                          systemImage: stage.icon)
                        .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                        .textCase(.uppercase).tracking(0.8)
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(Color.spaPrimary).sparkle()
                        Text("Spa Session").font(.system(size: 64, weight: .semibold))
                    }
                    Text(stage.instruction)
                        .font(.title3).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).frame(maxWidth: 480)
                }
                .padding(.top, 32)

                // Device + cloth illustration - switches per stage.
                ZStack {
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .fill(LinearGradient(colors: [.spaPrimary.opacity(0.12), .spaSecondary.opacity(0.08)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(Color.spaHairline))
                    DeviceArt(kind: stageKind, accent: .spaPrimary)
                        .frame(maxWidth: 360, maxHeight: 150)
                        .id(stageIndex)               // re-draw on stage change
                        .transition(.opacity)
                        .padding(24)
                    CleaningClothView(width: 180, height: 116, cornerRadius: 24, logoSize: 18)
                        .rotationEffect(.degrees(6))
                        .wipe()
                    Image(systemName: "sparkles").foregroundStyle(Color.spaPrimary)
                        .font(.title2).offset(x: -120, y: -60).sparkle()
                    Image(systemName: "sparkles").foregroundStyle(Color.spaSecondary)
                        .font(.title3).offset(x: 130, y: 60).sparkle(delay: 0.8)
                }
                .frame(maxWidth: 640)
                .frame(height: 220)
                .padding(.top, 24)
                .animation(.easeInOut, value: stageIndex)
                .onTapGesture { handleOverlayTap() }

                // Rotating quip
                Text("\u{201C}\(currentQuip)\u{201D}")
                    .font(.body).foregroundStyle(.secondary).italic()
                    .id(currentQuip)
                    .softIn()
                    .padding(.top, 20)

                // Timer + progress + controls
                VStack(spacing: 16) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Time left in this step")
                                .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                                .textCase(.uppercase).tracking(0.6)
                            Text(timeDisplay)
                                .font(.system(size: 56, weight: .semibold, design: .monospaced))
                                .contentTransition(.numericText())
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Unlock shortcut").font(.caption2).foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                ForEach(Array(HotKeyStore.load(.unlock).keyCaps.enumerated()), id: \.offset) { _, key in
                                    Text(key).font(.system(.caption2, design: .monospaced))
                                        .frame(minWidth: 22, minHeight: 22)
                                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                                        .overlay(RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color.secondary.opacity(0.3)))
                                }
                            }
                        }
                    }
                    ProgressView(value: progress)
                        .tint(GradientPrimary())
                        .scaleEffect(x: 1, y: 2)
                    HStack {
                        Label(stage.tip, systemImage: "lightbulb.fill").font(.caption).foregroundStyle(.secondary)
                            .frame(maxWidth: 360, alignment: .leading)
                        Spacer()
                        if stageIndex < stages.count - 1 {
                            Button("Next step") { nextStage() }.glass(cornerRadius: 12)
                        }
                        Button("End session") { endSession() }
                            .buttonStyle(.borderedProminent).tint(.primary)
                    }
                }
                .padding(24)
                .glassStrong(cornerRadius: 28)
                .shadow(color: .black.opacity(0.20), radius: 20, y: 8)   // largest surface reads thickest
                .frame(maxWidth: 640)
                .padding(.top, 20)

                Spacer()
            }
            .padding(.horizontal, 60)
        }
        .onAppear {
            currentQuip = personality.quip(for: stages[0].category)
            startTimers()
            playStageSound()
            // Apply the current unlock shortcut before blocking caches it.
            let unlock = HotKeyStore.load(.unlock)
            eventTap.unlockKeyCode = CGKeyCode(unlock.keyCode)
            eventTap.unlockModifiers = unlock.cgFlags
            eventTap.lockMode = stageLock
            // Keep input blocked through every stage; safety cap can only be longer.
            let totalStage = Int(stages.reduce(0) { $0 + $1.duration }) + 15
            blockSeconds = safetyTimeoutSeconds == 0 ? 0 : max(safetyTimeoutSeconds, totalStage)
            eventTap.startBlocking(timeoutSeconds: blockSeconds)
            eventTap.onUnlock = { Task { @MainActor in endSession() } }
        }
        .onDisappear { stopTimers() }
    }

    private func startTimers() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                // Re-arm the lock if it isn't engaged yet (e.g. Accessibility was just granted).
                if !eventTap.isBlocking { eventTap.startBlocking(timeoutSeconds: blockSeconds) }
                elapsed += 1
                totalElapsed += 1
                if elapsed >= stage.duration { advanceStage() }   // dedicated time up
            }
        }
        quipTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            Task { @MainActor in
                withAnimation { currentQuip = personality.quip(for: stages[stageIndex].category) }
            }
        }
    }

    private func stopTimers() { sessionTimer?.invalidate(); quipTimer?.invalidate() }

    private func nextStage() {
        guard stageIndex < stages.count - 1 else { return }
        stageIndex += 1; elapsed = 0
        eventTap.lockMode = stageLock
        currentQuip = personality.quip(for: stage.category)   // match new device immediately
        playStageSound()
    }

    /// Called when a stage's dedicated time runs out: advance or finish.
    private func advanceStage() {
        if stageIndex < stages.count - 1 { nextStage() } else { endSession() }
    }

    private func endSession() {
        stopTimers()
        eventTap.stopBlocking()
        if chimeOnCompletion && stageIndex >= stages.count - 1 {
            SoundService.playFinale()   // ace-style crescendo
        }
        if storeHistory && (stageIndex > 0 || elapsed > 10) {
            let session = CleaningSession(
                devices: Array(stages[0...stageIndex].map { $0.title }),
                wellnessBefore: 0
            )
            session.startDate = Date().addingTimeInterval(-totalElapsed)
            session.duration = totalElapsed
            session.completed = stageIndex >= stages.count - 1
            modelContext.insert(session)
        }
        onEnd()
    }

    private func handleOverlayTap() {
        overlayClickCount += 1
        if overlayClickCount >= 5 { endSession() }
    }

    /// Opens the Accessibility pane so the user can grant input-blocking permission.
    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
