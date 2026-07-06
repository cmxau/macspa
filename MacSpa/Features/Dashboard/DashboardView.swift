import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(EventTapService.self) private var eventTap
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CleaningSession.startDate, order: .reverse) private var sessions: [CleaningSession]
    // Observed so "Next spa" recomputes when reminder settings change on another tab.
    @AppStorage("reminderEnabled") private var reminderEnabled = true
    @AppStorage("reminderSchedule") private var reminderSchedule = "monthly"

    private var liveScore: Int { WellnessService.shared.score(sessions: sessions) }
    private var liveMood: DeviceMood { WellnessService.shared.mood(score: liveScore) }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Good morning."
        case 12..<17: return "Good afternoon."
        case 17..<22: return "Good evening."
        default:      return "Good night."
        }
    }
    private var lastCleanedText: String {
        guard let d = sessions.map({ $0.startDate }).max() else { return "Never" }
        return WellnessService.relative(d)
    }
    private var thisMonth: Int {
        sessions.filter { (Calendar.current.dateComponents([.day], from: $0.startDate, to: Date()).day ?? 999) < 30 }.count
    }
    private var nextSpaText: String {
        guard let d = ReminderService.nextDate() else { return "Not scheduled" }
        return WellnessService.relative(d).capitalizedFirst
    }
    // Semantic wellness signal: hue conveys state (green → amber → coral → red),
    // independent of the brand accent, so "needs help" never looks like "fresh".
    private var moodTint: Color {
        switch liveMood {
        case .fresh:          .spaSuccess
        case .happy:          .spaPrimary
        case .dusty:          .spaWarning
        case .needsAttention: .spaCoral
        case .sendHelp:       .spaCritical
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if sessions.isEmpty {
                    EmptyWellnessCard {
                        SessionWindowController.shared.show(appState: appState, eventTap: eventTap, container: modelContext.container)
                    }
                } else {
                    hero
                    HStack(alignment: .top, spacing: 16) {
                        TotalCareCard().frame(maxWidth: .infinity, maxHeight: .infinity)
                        RecentHistoryCard().frame(maxWidth: .infinity, maxHeight: .infinity)
                        RecentAchievementsCard().frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .padding(2)
            .softIn()
        }
        .onAppear { appState.refreshWellness(sessions: sessions) }
        .onChange(of: sessions.count) { _, _ in appState.refreshWellness(sessions: sessions) }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting).font(.subheadline).foregroundStyle(.secondary)
                if sessions.isEmpty {
                    Text("Your Mac is waiting.")
                        .font(.system(size: 38, weight: .bold)).tracking(-0.5)
                } else {
                    (Text("Your Mac feels ").foregroundStyle(.primary)
                     + Text(liveMood.label.lowercased()).foregroundStyle(moodTint)
                     + Text("."))
                        .font(.system(size: 38, weight: .bold)).tracking(-0.5)
                }
            }
            Spacer()
            Button("Begin Spa") {
                SessionWindowController.shared.show(appState: appState, eventTap: eventTap, container: modelContext.container)
            }
            .buttonStyle(PrimaryButtonStyle(icon: nil, size: .large))
        }
    }

    private let statCols = [GridItem(.flexible(), spacing: 24),
                            GridItem(.flexible(), spacing: 24),
                            GridItem(.flexible(), spacing: 24)]

    private var hero: some View {
        GlassCard(padding: 28, cornerRadius: 28) {
            HStack(alignment: .center, spacing: 32) {
                // Ring column
                VStack(spacing: 12) {
                    RingView(value: Double(liveScore), label: "\(liveScore)", size: 172, tint: .spaPrimary)
                    VStack(spacing: 3) {
                        Text(WellnessService.shared.band(score: liveScore))
                            .font(.title3.weight(.bold)).foregroundStyle(Color.spaPrimary)
                        Text("Device wellness")
                            .font(.caption2.weight(.semibold)).tracking(0.8)
                            .textCase(.uppercase).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 196)

                Divider().frame(height: 176)

                // Stats grid
                LazyVGrid(columns: statCols, alignment: .leading, spacing: 26) {
                    HeroStat(icon: liveMood.symbol, tint: moodTint, label: "Mood",
                             value: liveMood.label, hint: "Wellness \(liveScore)", face: liveMood.expression)
                    HeroStat(icon: "clock.arrow.circlepath", tint: .spaPrimary, label: "Last cleaned",
                             value: lastCleanedText, hint: "Most recent spa")
                    HeroStat(icon: "bell.badge.fill", tint: .spaPrimary, label: "Next spa",
                             value: nextSpaText, hint: "From reminders")
                    HeroStat(icon: "sparkles", tint: .spaPrimary, label: "Rituals",
                             value: "\(sessions.count)", hint: "All time")
                    HeroStat(icon: "calendar", tint: .spaPrimary, label: "This month",
                             value: "\(thisMonth)", hint: "Last 30 days")
                    HeroStat(icon: "gauge.medium", tint: .spaPrimary, label: "Days since",
                             value: (WellnessService.shared.daysSinceLast(sessions).map { "\($0)" }) ?? "-",
                             hint: "Last cleaning")
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Empty state

private struct EmptyWellnessCard: View {
    let onStart: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            IconTile(systemName: "heart.circle.fill", color: .spaPrimary, size: 66, symbolSize: 30)
                .breathe()
            Text("Give your Mac its first spa session").font(.title3.weight(.bold))
            Text("The love it truly deserves. Start a gentle ritual and watch its wellness bloom.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).frame(maxWidth: 360)
            Button("Begin Spa", action: onStart)
                .buttonStyle(PrimaryButtonStyle(icon: nil, size: .large))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
        .background(
            LinearGradient(colors: [.spaPrimarySoft.opacity(0.14), .spaPrimary.opacity(0.07)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Color.spaHairline, lineWidth: 1))
    }
}

// MARK: - Hero stat

private struct HeroStat: View {
    var icon: String; var tint: Color; var label: String; var value: String; var hint: String?
    /// When set, draws a mood face instead of the SF icon tile.
    var face: MoodExpression? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                if let face {
                    RoundedRectangle(cornerRadius: 28 * 0.3, style: .continuous)
                        .fill(tint.opacity(0.14))
                        .frame(width: 28, height: 28)
                        .overlay(MoodFace(expression: face, color: tint).padding(5))
                } else {
                    IconTile(systemName: icon, color: tint, size: 28, symbolSize: 12)
                }
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold)).tracking(0.5)
                    .foregroundStyle(.secondary).lineLimit(1)
            }
            Text(value).font(.title3.weight(.bold)).lineLimit(1).minimumScaleFactor(0.6)
            if let hint {
                Text(hint).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .topLeading)
    }
}

// MARK: - Total care (real, all-time minutes cleaned)

private struct TotalCareCard: View {
    @Query private var sessions: [CleaningSession]

    private var totalSeconds: Int { Int(sessions.reduce(0.0) { $0 + $1.duration }) }
    private var completed: Int { sessions.filter { $0.completed }.count }

    /// Whole minutes cleaned, plus a compact "Xh Ym" form once it passes an hour.
    private var timeValue: String {
        let m = totalSeconds / 60
        if m >= 60 { return "\(m / 60)h \(m % 60)m" }
        if m > 0   { return "\(m) min" }
        return "\(totalSeconds)s"
    }

    var body: some View {
        GlassCard {
            CardEyebrow(systemName: "clock.badge.checkmark", title: "Total care", hint: "All time", color: .spaPrimary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(timeValue).font(.system(size: 34, weight: .bold)).minimumScaleFactor(0.6).lineLimit(1)
            }
            .padding(.top, 2)
            Text("\(sessions.count) session\(sessions.count == 1 ? "" : "s") · \(completed) full ritual\(completed == 1 ? "" : "s")")
                .font(.caption).foregroundStyle(.secondary)
            // Slim proportion bar: share of sessions completed as a full ritual.
            GeometryReader { geo in
                let frac = sessions.isEmpty ? 0 : Double(completed) / Double(sessions.count)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.spaPrimary.opacity(0.12))
                    Capsule().fill(GradientPrimary())
                        .frame(width: max(6, geo.size.width * frac))
                }
            }
            .frame(height: 8)
            .padding(.top, 6)
            Text("Time your Mac has spent at the spa.")
                .font(.caption2).foregroundStyle(.tertiary).padding(.top, 2)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Recent history (real)

private struct RecentHistoryCard: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \CleaningSession.startDate, order: .reverse) private var sessions: [CleaningSession]

    private var recent: [CleaningSession] { Array(sessions.prefix(3)) }

    var body: some View {
        GlassCard {
            HStack {
                CardEyebrow(systemName: "clock.fill", title: "History", color: .spaPrimary)
                Button("View all") { appState.selectedTab = .history }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.spaPrimary).buttonStyle(.plain)
            }
            if recent.isEmpty {
                Text("No sessions yet. Start your first spa session.")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 10)
            } else {
                VStack(spacing: 0) {
                    ForEach(recent.indices, id: \.self) { i in
                        let s = recent[i]
                        HStack(spacing: 11) {
                            CalendarDateBadge(date: s.startDate, size: 38)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(deviceLabel(s)).font(.subheadline.weight(.semibold))
                                Text(dateText(s.startDate)).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(durationText(s.duration)).font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.spaSecondary)
                        }
                        .padding(.vertical, 8)
                        if i < recent.count - 1 { Divider().opacity(0.5) }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func deviceLabel(_ s: CleaningSession) -> String {
        let names = s.devices.map { $0.replacingOccurrences(of: " Care", with: "")
            .replacingOccurrences(of: " Polish", with: "").replacingOccurrences(of: " Refresh", with: "") }
        if names.count >= 3 { return "Full ritual" }
        return names.isEmpty ? "Spa session" : names.joined(separator: " + ")
    }
    private func dateText(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: d)   // date shown in badge
    }
    private func durationText(_ t: TimeInterval) -> String {
        let s = Int(t); let m = s / 60; let sec = s % 60
        return m > 0 ? "\(m)m \(sec)s" : "\(sec)s"
    }
}

// MARK: - Recent achievements (real)

private struct RecentAchievementsCard: View {
    @Environment(AppState.self) private var appState
    @Query private var sessions: [CleaningSession]

    private var featured: [Milestone] {
        Milestone.all(sessions: sessions)
            .sorted { a, b in
                if a.unlocked != b.unlocked { return a.unlocked && !b.unlocked }
                return a.progress > b.progress
            }
            .prefix(3).map { $0 }
    }

    var body: some View {
        GlassCard {
            HStack {
                CardEyebrow(systemName: "rosette", title: "Achievements", color: .spaPrimary)
                Button("See all") { appState.selectedTab = .achievements }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.spaPrimary).buttonStyle(.plain)
            }
            VStack(spacing: 8) {
                ForEach(featured) { m in
                    HStack(spacing: 11) {
                        IconTile(systemName: m.icon, color: m.unlocked ? .spaPrimary : .secondary, size: 34, symbolSize: 15)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(m.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                            Text(m.unlocked
                                 ? (m.timesEarned > 1 ? "Earned \(m.timesEarned)×" : "Unlocked")
                                 : m.progressText)
                                .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        if m.unlocked {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption).foregroundStyle(Color.spaPrimary)
                        } else {
                            Text("\(Int(m.progress * 100))%")
                                .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Helpers

extension String {
    var capitalizedFirst: String { isEmpty ? self : prefix(1).uppercased() + dropFirst() }
}
