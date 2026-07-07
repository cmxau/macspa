import SwiftUI

struct HealthView: View {
    @Environment(AppState.self) private var appState

    private var snapshot: HealthSnapshot { appState.health }
    private var loading: Bool { appState.healthScanning }

    private let cols = [GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)]

    private var lastScanText: String {
        guard let d = appState.healthScannedAt else { return "Not scanned yet" }
        return "Last scan " + WellnessService.relative(d)
    }

    /// Semantic status color for a 0–100 sub-score (matches wellness palette).
    static func statusColor(_ score: Int) -> Color {
        switch score {
        case 80...:  return .spaSuccess
        case 60..<80: return .spaPrimary
        case 40..<60: return .spaWarning
        default:      return .spaCoral
        }
    }
    private var scoreTint: Color { Self.statusColor(snapshot.score) }
    private var band: String {
        switch snapshot.score {
        case 80...:   return "Healthy"
        case 60..<80: return "Good"
        case 40..<60: return "Needs care"
        default:      return "At risk"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    SectionHeader(eyebrow: "Mac Health", title: "Grounded in real signals.")
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Button { Task { await appState.scanHealth() } } label: {
                            Label(loading ? "Scanning…" : "Rescan", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .disabled(loading)
                        Text(lastScanText).font(.caption2).foregroundStyle(.tertiary)
                    }
                }

                if loading && snapshot.metrics.isEmpty {
                    ProgressView("Reading your Mac…")
                        .frame(maxWidth: .infinity, minHeight: 260)
                } else {
                    hero
                    LazyVGrid(columns: cols, spacing: 16) {
                        ForEach(snapshot.metrics) { MetricCard(metric: $0) }
                    }
                }
            }
            .padding(2)
            .softIn()
        }
        // Cached: scans once, then only on manual Rescan (not on every tab visit).
        .task { await appState.scanHealthIfNeeded() }
    }

    private var hero: some View {
        GlassCard(padding: 28, cornerRadius: 28) {
            HStack(alignment: .center, spacing: 32) {
                VStack(spacing: 12) {
                    RingView(value: Double(snapshot.score), label: "\(snapshot.score)",
                             sublabel: "Health", size: 172, tint: scoreTint)
                    VStack(spacing: 3) {
                        Text(band).font(.title3.weight(.bold)).foregroundStyle(scoreTint)
                        Text("Mac health")
                            .font(.caption2.weight(.semibold)).tracking(0.8)
                            .textCase(.uppercase).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 196)

                Divider().frame(height: 176)

                VStack(alignment: .leading, spacing: 12) {
                    Text("A live read of what actually affects your Mac day to day - storage, memory, uptime, battery, and reclaimable clutter.")
                        .font(.callout).foregroundStyle(.secondary).frame(maxWidth: 360, alignment: .leading)
                    Text("Nothing is changed or sent anywhere - this is a read-only checkup.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct MetricCard: View {
    let metric: HealthMetric
    private var tint: Color { HealthView.statusColor(metric.score) }

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                IconTile(systemName: metric.icon, color: tint, size: 40, symbolSize: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text(metric.title.uppercased())
                        .font(.caption2.weight(.semibold)).tracking(0.6).foregroundStyle(.secondary)
                    Text(metric.value).font(.title3.weight(.bold)).lineLimit(1).minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
            }
            Text(metric.detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            // Score bar in the metric's status color.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(tint.opacity(0.14))
                    Capsule().fill(tint).frame(width: max(6, geo.size.width * Double(metric.score) / 100))
                }
            }
            .frame(height: 6)
            .padding(.top, 2)
        }
    }
}
