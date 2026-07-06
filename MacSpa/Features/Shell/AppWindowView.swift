import SwiftUI

struct AppWindowView: View {
    @Environment(AppState.self) private var appState
    // Rebuild the tree on accent change so every leaf view recolors instantly.
    @AppStorage("accentColor") private var accentColor = "blue"

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .frame(width: 250)

            ZStack {
                HeroBackground()
                detailView
                    .padding(appState.selectedTab == .settings ? 0 : 34)
            }
        }
        .frame(minWidth: 1080, minHeight: 700)
        .background(Color.spaCanvas)
        .id(accentColor)
        .scrollIndicators(.hidden)   // hide scrollbars app-wide (propagates to child scroll views)
    }

    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedTab {
        case .dashboard:    DashboardView()
        case .guided:       GuidedCleaningView()
        case .health:       HealthView()
        case .history:      HistoryView()
        case .achievements: AchievementsView()
        case .settings:     SettingsView()
        }
    }
}

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(EventTapService.self) private var eventTap
    @Environment(\.modelContext) private var modelContext

    private let groups: [(String, [AppTab])] = [
        ("Overview",  [.dashboard, .guided, .health]),
        ("Insights",  [.history, .achievements]),
        ("System",    [.settings]),
    ]

    private func scheduleText(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d · h:mm a"; return f.string(from: d)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Brand
            HStack(spacing: 10) {
                AppLogo()
                    .frame(width: 32, height: 32)
                Text("MacSpa").font(.title3.weight(.bold))
            }
            .padding(.horizontal, 22)
            .padding(.top, 26)
            .padding(.bottom, 24)

            // Nav
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(groups, id: \.0) { group, tabs in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.uppercased())
                                .font(.caption2.weight(.semibold))
                                .tracking(1.2)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 22)
                                .padding(.bottom, 4)
                            ForEach(tabs) { tab in
                                NavRow(tab: tab, selected: appState.selectedTab == tab) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        appState.selectedTab = tab
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
            }

            Spacer(minLength: 8)

            // Next spa card
            VStack(alignment: .leading, spacing: 8) {
                TintedTag(text: "Next spa session", systemName: "bell.badge.fill", color: .spaPrimary)
                if let d = ReminderService.nextDate() {
                    Text(WellnessService.relative(d).capitalizedFirst)
                        .font(.headline)
                    Text(scheduleText(d)).font(.caption2).foregroundStyle(.secondary)
                } else {
                    Text("Not scheduled").font(.headline)
                    Button("Set a reminder") { appState.selectedTab = .settings }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.spaPrimary).buttonStyle(.plain)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                LinearGradient(colors: [.spaPrimary.opacity(0.12), .spaPrimarySoft.opacity(0.08)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .surfaceMaterial(cornerRadius: 0, strong: true)   // heavier structural sidebar material
    }
}

private struct NavRow: View {
    let tab: AppTab
    let selected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(selected ? Color.spaPrimary : .secondary)
                    .frame(width: 22)
                Text(tab.label)
                    .font(.subheadline.weight(selected ? .semibold : .regular))
                    .foregroundStyle(selected ? .primary : .secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? Color.spaPrimary.opacity(0.12)
                                   : (hovering ? Color.primary.opacity(0.05) : .clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
