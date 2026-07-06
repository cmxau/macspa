// HistoryView.swift
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \CleaningSession.startDate, order: .reverse) private var sessions: [CleaningSession]
    @AppStorage("storeHistory") private var storeHistory = true

    // Group sessions by month, preserving newest-first order.
    private var groups: [(month: String, items: [CleaningSession])] {
        let fmt = DateFormatter(); fmt.dateFormat = "MMMM yyyy"
        var order: [String] = []
        var map: [String: [CleaningSession]] = [:]
        for s in sessions {
            let key = fmt.string(from: s.startDate)
            if map[key] == nil { order.append(key); map[key] = [] }
            map[key]?.append(s)
        }
        return order.map { ($0, map[$0] ?? []) }
    }

    private var totalMinutes: Int {
        Int(sessions.reduce(0.0) { $0 + $1.duration } / 60)
    }

    var body: some View {
        ZStack {
            content
                .blur(radius: storeHistory ? 0 : 10)
                .disabled(!storeHistory)

            if !storeHistory {
                EnableOverlay(icon: "externaldrive.badge.checkmark", title: "History is off",
                              message: "Turn on local history to save and review your spa sessions.",
                              button: "Enable History") {
                    storeHistory = true
                }
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                SectionHeader(eyebrow: "History", title: "A timeline of care.")

                if sessions.isEmpty {
                    EmptyHistory()
                } else {
                    HStack(spacing: 8) {
                        TintedTag(text: "\(sessions.count) session\(sessions.count == 1 ? "" : "s")",
                                  systemName: "sparkles", color: .spaPrimary)
                        TintedTag(text: "\(totalMinutes) min cleaned",
                                  systemName: "clock.fill", color: .spaSuccess)
                    }

                    ForEach(groups, id: \.month) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.month.uppercased())
                                .font(.caption.weight(.semibold)).tracking(1.2)
                                .foregroundStyle(.tertiary)
                            VStack(spacing: 12) {
                                ForEach(group.items) { session in
                                    SessionRow(session: session)
                                }
                            }
                        }
                    }
                }
            }
            .padding(2)
            .softIn()
        }
    }
}

// MARK: - Row

private struct SessionRow: View {
    let session: CleaningSession

    private var devices: [String] { session.devices.map(Self.shortName) }

    private var dateText: String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"   // date shown in the badge; text shows the time
        return f.string(from: session.startDate)
    }
    private var durationText: String {
        let s = Int(session.duration); let m = s / 60; let sec = s % 60
        return m > 0 ? "\(m)m \(sec)s" : "\(sec)s"
    }

    var body: some View {
        HStack(spacing: 14) {
            CalendarDateBadge(date: session.startDate)
            VStack(alignment: .leading, spacing: 6) {
                Text(devices.isEmpty ? "Spa session" : devices.joined(separator: " + ")).font(.headline)
                Text(dateText).font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 5) {
                    ForEach(devices, id: \.self) { d in
                        Text(d).font(.caption2.weight(.medium))
                            .padding(.horizontal, 9).padding(.vertical, 3)
                            .background(Color.spaPrimary.opacity(0.1), in: Capsule())
                            .foregroundStyle(Color.spaPrimary)
                    }
                }
            }
            Spacer()
            metric("Duration", durationText, .primary)
            // Any recorded session counts as care - status always reads green.
            metric("Status", session.completed ? "Complete" : "Partial", .spaSuccess)
        }
        .padding(16)
        .surfaceMaterial(cornerRadius: 20)
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.spaHairline, lineWidth: 1))
        .hoverLift()
    }

    private func metric(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(label.uppercased()).font(.caption2.weight(.semibold)).tracking(0.5).foregroundStyle(.tertiary)
            Text(value).font(.subheadline.weight(.bold)).foregroundStyle(color)
        }
        .frame(minWidth: 82, alignment: .trailing)
    }

    /// Maps a stored stage title ("Keyboard Care") to a short device label.
    static func shortName(_ s: String) -> String {
        if s.contains("Keyboard") { return "Keyboard" }
        if s.contains("Trackpad") { return "Trackpad" }
        if s.contains("Display")  { return "Display" }
        return s
    }
}

// MARK: - Empty state

private struct EmptyHistory: View {
    var body: some View {
        VStack(spacing: 12) {
            IconTile(systemName: "clock.badge.questionmark", color: .spaPrimary, size: 56, symbolSize: 24)
            Text("No sessions yet").font(.headline)
            Text("Your spa sessions will appear here once you finish your first one.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
        .surfaceMaterial(cornerRadius: 22)
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.spaHairline, lineWidth: 1))
    }
}

// MARK: - Enable overlay (shown centered over a blurred, disabled section)

struct EnableOverlay: View {
    let icon: String
    let title: String
    let message: String
    let button: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            IconTile(systemName: icon, color: .spaPrimary, size: 58, symbolSize: 26)
            Text(title).font(.title3.weight(.bold))
            Text(message).font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).frame(maxWidth: 300)
            Button(button, action: action)
                .buttonStyle(PrimaryButtonStyle(icon: "checkmark"))
                .padding(.top, 4)
        }
        .padding(32)
        .surfaceMaterial(cornerRadius: 26)
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Color.spaHairline, lineWidth: 1))
        .padding(24)
    }
}
