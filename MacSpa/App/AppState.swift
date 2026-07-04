import SwiftUI
import Observation

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard, guided, health, history, achievements, settings
    var id: String { rawValue }

    var label: String {
        switch self {
        case .dashboard: "Wellness"
        case .guided: "Guided Cleaning"
        case .health: "Mac Health"
        case .history: "History"
        case .achievements: "Achievements"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "heart.fill"
        case .guided: "wind"
        case .health: "waveform.path.ecg"
        case .history: "clock.fill"
        case .achievements: "trophy.fill"
        case .settings: "gearshape.fill"
        }
    }

    var group: String {
        switch self {
        case .dashboard, .guided, .health: "Overview"
        case .history, .achievements: "Insights"
        case .settings: "System"
        }
    }
}

enum DeviceMood: String {
    case fresh = "Fresh"
    case happy = "Happy"
    case dusty = "Dusty"
    case needsAttention = "Needs Attention"
    case sendHelp = "Send Help"

    var label: String { rawValue }

    /// SF Symbol face for the tiny menu-bar glyph (no frown face exists, so the
    /// low moods fall back to a neutral dashed face; in-app spots use `MoodFace`).
    var symbol: String {
        switch self {
        case .fresh:          "smiley.fill"
        case .happy:          "face.smiling.fill"
        case .dusty:          "face.smiling"
        case .needsAttention: "face.dashed"
        case .sendHelp:       "face.dashed.fill"
        }
    }
}

@Observable
final class AppState {
    var selectedTab: AppTab = .dashboard
    var isSessionActive: Bool = false
    var showOnboarding: Bool

    init() {
        showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    // Wellness - mood published for the menu-bar icon; refreshed from sessions.
    var mood: DeviceMood = .fresh

    /// Recompute the published mood from real session history. Called by views
    /// that hold a live @Query of sessions.
    func refreshWellness(sessions: [CleaningSession]) {
        let score = WellnessService.shared.score(sessions: sessions)
        let m = WellnessService.shared.mood(score: score)
        if m != mood { mood = m }
    }

    // MARK: Mac Health (cached - scanned once, then only on manual Rescan)

    var health: HealthSnapshot = .empty
    var healthScannedAt: Date?
    var healthScanning = false

    /// Runs a fresh system scan and caches the result + timestamp.
    @MainActor func scanHealth() async {
        guard !healthScanning else { return }
        healthScanning = true
        health = await SystemHealthService.snapshot()
        healthScannedAt = Date()
        healthScanning = false
    }

    /// Scans only if we have never scanned this launch (so re-entering the tab
    /// shows the cached result instead of rescanning every time).
    @MainActor func scanHealthIfNeeded() async {
        if healthScannedAt == nil { await scanHealth() }
    }
}
