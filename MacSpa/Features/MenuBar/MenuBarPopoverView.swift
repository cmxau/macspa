import SwiftUI
import AppKit
import SwiftData

struct MenuBarPopoverView: View {
    @Environment(AppState.self) private var appState
    @Environment(EventTapService.self) private var eventTap
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CleaningSession.startDate, order: .reverse) private var sessions: [CleaningSession]

    private var health: HealthSnapshot { appState.health }
    private var score: Int { WellnessService.shared.score(sessions: sessions) }
    private var mood: DeviceMood { WellnessService.shared.mood(score: score) }

    var body: some View {
        VStack(spacing: 6) {
            // Mood + the two scores: spa wellness and real Mac health.
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    MoodFace(expression: mood.expression, color: .spaPrimary)
                        .frame(width: 22, height: 22)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Device mood").font(.caption2).foregroundStyle(.secondary)
                        Text(mood.label).font(.subheadline.weight(.semibold))
                    }
                }
                Spacer()
                miniStat("Wellness", "\(score)", .spaPrimary)
                miniStat("Health", health.score > 0 ? "\(health.score)" : "-",
                         HealthView.statusColor(health.score))
            }
            .padding(.horizontal, 10).padding(.top, 2)

            Divider()

            VStack(spacing: 1) {
                MenuRow(icon: "sparkles", title: "Begin Spa", trailing: nil) {
                    SessionWindowController.shared.show(appState: appState, eventTap: eventTap, container: modelContext.container)
                }
                MenuRow(icon: "waveform.path.ecg", title: "Mac Health", trailing: nil) {
                    appState.selectedTab = .health
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
                MenuRow(icon: "square.grid.2x2.fill", title: "Open Dashboard", trailing: nil) {
                    appState.selectedTab = .dashboard
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
                MenuRow(icon: "power", title: "Quit MacSpa", trailing: "⌘Q", destructive: true) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(8)
        .frame(width: 240)
        .onAppear { appState.refreshWellness(sessions: sessions) }
        .onChange(of: sessions.count) { _, _ in appState.refreshWellness(sessions: sessions) }
        .task { await appState.scanHealthIfNeeded() }
    }

    private func miniStat(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.system(size: 22, weight: .semibold, design: .rounded)).foregroundStyle(tint)
        }
        .frame(minWidth: 44)
    }
}

/// A single tappable row in the menu-bar popover.
private struct MenuRow: View {
    let icon: String
    let title: String
    var trailing: String? = nil
    var destructive: Bool = false
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).frame(width: 20)
                Text(title)
                Spacer()
                if let trailing {
                    Text(trailing).font(.caption).foregroundStyle(.tertiary)
                } else {
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 7)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(hovering ? Color.primary.opacity(0.06) : .clear)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(destructive ? Color.spaCritical : .primary)
        .onHover { hovering = $0 }
    }
}
