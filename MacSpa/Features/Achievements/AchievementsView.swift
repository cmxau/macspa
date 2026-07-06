// AchievementsView.swift
import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query private var sessions: [CleaningSession]

    private var milestones: [Milestone] { Milestone.all(sessions: sessions) }

    private var sorted: [Milestone] {
        milestones.sorted { a, b in
            if a.unlocked != b.unlocked { return a.unlocked && !b.unlocked }
            return a.progress > b.progress
        }
    }
    private var unlockedCount: Int { milestones.filter { $0.unlocked }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(eyebrow: "Achievements", title: "Small rituals. Bright badges.")

                TintedTag(text: "\(unlockedCount) of \(milestones.count) unlocked",
                          systemName: "rosette", color: .spaPrimary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                    ForEach(sorted) { badge in BadgeCard(badge: badge) }
                }
                .padding(.top, 4)
            }
            .padding(2)
            .softIn()
        }
    }
}

// MARK: - Milestone model + real-data builder

struct Milestone: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let current: Double
    let target: Double
    let unit: String
    var repeatable: Bool = true

    var progress: Double { target <= 0 ? 0 : min(1, current / target) }
    var unlocked: Bool { current >= target }

    /// How many times earned, Apple-Workouts style. Repeatable milestones count
    /// every multiple of the target; one-off milestones cap at 1.
    var timesEarned: Int {
        guard target > 0 else { return unlocked ? 1 : 0 }
        return repeatable ? Int(current / target) : (unlocked ? 1 : 0)
    }

    private func fmt(_ v: Double) -> String {
        unit == " km" ? String(format: "%.0f", v) : Int(v).formatted()
    }
    var progressText: String { "\(fmt(min(current, target))) / \(fmt(target))\(unit)" }

    /// Every milestone, computed live from real cleaning history.
    static func all(sessions: [CleaningSession]) -> [Milestone] {
        let total = Double(sessions.count)
        let completed = Double(sessions.filter { $0.completed }.count)
        let cleanMinutes = sessions.reduce(0.0) { $0 + $1.duration } / 60

        return [
            Milestone(id: "fresh-start", title: "Fresh Start", detail: "Finish your first spa session.",
                      icon: "leaf.fill", current: total, target: 1, unit: " sessions", repeatable: false),
            Milestone(id: "getting-tidy", title: "Getting Tidy", detail: "Complete 5 spa sessions.",
                      icon: "sparkles", current: total, target: 5, unit: " sessions"),
            Milestone(id: "spa-regular", title: "Spa Regular", detail: "Complete 25 spa sessions.",
                      icon: "camera.macro", current: total, target: 25, unit: " sessions"),
            Milestone(id: "zen-master", title: "Zen Master", detail: "Complete 100 spa sessions.",
                      icon: "figure.mind.and.body", current: total, target: 100, unit: " sessions"),
            Milestone(id: "full-ritual", title: "Full Ritual", detail: "Finish a full keyboard, trackpad & display ritual.",
                      icon: "checkmark.seal.fill", current: completed, target: 1, unit: ""),
            Milestone(id: "deep-clean", title: "Deep Clean", detail: "Spend 60 minutes cleaning in total.",
                      icon: "clock.badge.checkmark.fill", current: cleanMinutes, target: 60, unit: " min"),
        ]
    }
}

// MARK: - Card

private struct BadgeCard: View {
    let badge: Milestone
    /// Unlocked achievements use the brand accent; locked ones stay muted.
    private var accent: Color { badge.unlocked ? .spaPrimary : Color.secondary }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(badge.unlocked ? accent.opacity(0.16) : Color.primary.opacity(0.05))
                    .frame(width: 84, height: 84)
                Image(systemName: badge.icon)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(badge.unlocked ? accent : Color.secondary.opacity(0.5))
            }
            .overlay(alignment: .topTrailing) {
                if badge.timesEarned > 1 {
                    Text("\(badge.timesEarned)×")
                        .font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(accent, in: Capsule())
                        .overlay(Capsule().stroke(Color.spaSurface, lineWidth: 2))
                        .offset(x: 6, y: -2)
                }
            }
            .modifier(BreatheIf(active: badge.unlocked))

            Text(badge.title).font(.headline).padding(.top, 16)
            Text(badge.detail).font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.top, 2)

            if badge.unlocked {
                Text(badge.timesEarned > 1 ? "EARNED \(badge.timesEarned)×" : "UNLOCKED")
                    .font(.caption2.weight(.bold)).tracking(1.2)
                    .foregroundStyle(accent)
                    .padding(.top, 12)
            } else {
                VStack(spacing: 5) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.primary.opacity(0.07))
                            Capsule().fill(Color.spaPrimary).frame(width: geo.size.width * badge.progress)
                        }
                    }
                    .frame(height: 6)
                    Text(badge.progressText)
                        .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.top, 14)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        // Solid surface whether locked or unlocked; unlocked keeps its accent border.
        .background(Color.spaSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(badge.unlocked ? accent.opacity(0.35) : Color.spaHairline, lineWidth: 1))
        .hoverLift()
    }
}

private struct BreatheIf: ViewModifier {
    let active: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if active { content.breathe() } else { content }
    }
}
