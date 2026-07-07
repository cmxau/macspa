import Foundation
import IOKit

/// A single system-health reading with a 0–100 sub-score and a human value.
struct HealthMetric: Identifiable, Sendable {
    let id: String
    let title: String
    let icon: String
    let value: String        // headline, e.g. "142 GB free"
    let detail: String       // supporting line, e.g. "68% of 500 GB"
    let score: Int           // 0–100
}

/// A full snapshot: per-metric readings plus a composite Mac-health score.
struct HealthSnapshot: Sendable {
    var metrics: [HealthMetric]
    var score: Int           // composite 0–100

    static let empty = HealthSnapshot(metrics: [], score: 0)
}

/// Reads real, grounded system-health signals - storage, memory, uptime, battery,
/// and junk - entirely from user-level APIs (no sandbox, no admin). Each signal
/// becomes a 0–100 sub-score; their mean is the Mac-health number.
enum SystemHealthService {

    /// Gathers a fresh snapshot off the main thread.
    static func snapshot() async -> HealthSnapshot {
        await Task.detached(priority: .utility) { readSnapshot() }.value
    }

    private static func readSnapshot() -> HealthSnapshot {
        var metrics: [HealthMetric] = []
        if let m = storageMetric() { metrics.append(m) }
        if let m = memoryMetric()  { metrics.append(m) }
        metrics.append(uptimeMetric())
        if let m = batteryMetric() { metrics.append(m) }   // omitted on desktops
        metrics.append(junkMetric())

        let score = metrics.isEmpty ? 0 : Int((Double(metrics.map(\.score).reduce(0, +)) / Double(metrics.count)).rounded())
        return HealthSnapshot(metrics: metrics, score: score)
    }

    // MARK: Storage

    private static func storageMetric() -> HealthMetric? {
        let url = URL(fileURLWithPath: "/")
        guard let vals = try? url.resourceValues(forKeys: [
            .volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]),
              let total = vals.volumeTotalCapacity, total > 0,
              let freeImportant = vals.volumeAvailableCapacityForImportantUsage
        else { return nil }

        let free = Double(freeImportant)
        let pct = free / Double(total)
        // ≥30% free → 100; ≤5% → 10.
        let score = lerpScore(pct, lo: 0.05, hi: 0.30, loScore: 10, hiScore: 100)
        return HealthMetric(
            id: "storage", title: "Storage", icon: "internaldrive.fill",
            value: "\(gb(freeImportant)) free",
            detail: "\(Int(pct * 100))% of \(gb(Int64(total)))",
            score: score)
    }

    // MARK: Memory

    private static func memoryMetric() -> HealthMetric? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let host = mach_host_self()
        let ok = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        guard ok == KERN_SUCCESS else { return nil }

        var pageSize: vm_size_t = 0
        host_page_size(host, &pageSize)
        let page = UInt64(pageSize)
        let total = ProcessInfo.processInfo.physicalMemory
        guard total > 0 else { return nil }
        // "Available" ≈ free + inactive + purgeable + speculative.
        let available = (UInt64(stats.free_count) + UInt64(stats.inactive_count)
                         + UInt64(stats.purgeable_count) + UInt64(stats.speculative_count)) * page
        let pct = Double(available) / Double(total)
        // ≥40% available → 100; ≤10% → 20.
        let score = lerpScore(pct, lo: 0.10, hi: 0.40, loScore: 20, hiScore: 100)
        return HealthMetric(
            id: "memory", title: "Memory", icon: "memorychip.fill",
            value: "\(gb(Int64(available))) free",
            detail: "\(Int(pct * 100))% of \(gb(Int64(total)))",
            score: score)
    }

    // MARK: Uptime

    private static func uptimeMetric() -> HealthMetric {
        var tv = timeval()
        var size = MemoryLayout<timeval>.stride
        sysctlbyname("kern.boottime", &tv, &size, nil, 0)
        let boot = Double(tv.tv_sec)
        let days = max(0, (Date().timeIntervalSince1970 - boot) / 86_400)
        // ≤2 days → 100; ≥14 days → 30.
        let score = lerpScore(days, lo: 14, hi: 2, loScore: 30, hiScore: 100)
        let d = Int(days.rounded())
        return HealthMetric(
            id: "uptime", title: "Uptime", icon: "clock.arrow.2.circlepath",
            value: d == 0 ? "Today" : "\(d) day\(d == 1 ? "" : "s")",
            detail: days >= 7 ? "A restart is due" : "Since last restart",
            score: score)
    }

    // MARK: Battery (nil on desktops)

    private static func batteryMetric() -> HealthMetric? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else { return nil }

        let cycles = dict["CycleCount"] as? Int
        let maxCap = (dict["AppleRawMaxCapacity"] as? Int) ?? (dict["MaxCapacity"] as? Int)
        let designCap = dict["DesignCapacity"] as? Int

        var healthPct: Int?
        if let maxCap, let designCap, designCap > 0 {
            healthPct = Int((Double(maxCap) / Double(designCap) * 100).rounded())
        }

        // Score from capacity health; ≥90% → 100, ≤60% → 30.
        let score: Int
        if let h = healthPct {
            score = lerpScore(Double(h), lo: 60, hi: 90, loScore: 30, hiScore: 100)
        } else {
            score = 80   // unknown → neutral-good
        }
        let value = healthPct.map { "\($0)% capacity" } ?? "Battery"
        let detail = cycles.map { "\($0) cycles" } ?? "Health"
        return HealthMetric(id: "battery", title: "Battery", icon: "battery.100percent",
                            value: value, detail: detail, score: score)
    }

    // MARK: Junk (measure only)

    private static func junkMetric() -> HealthMetric {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dirs = [
            home.appendingPathComponent("Library/Caches"),
            home.appendingPathComponent(".Trash"),
            home.appendingPathComponent("Library/Developer/Xcode/DerivedData"),
        ]
        let bytes = dirs.reduce(Int64(0)) { $0 + directorySize($1) }
        let gbVal = Double(bytes) / 1_000_000_000
        // ≤1 GB → 100; ≥25 GB → 30.
        let score = lerpScore(gbVal, lo: 25, hi: 1, loScore: 30, hiScore: 100)
        return HealthMetric(
            id: "junk", title: "Reclaimable", icon: "trash.fill",
            value: gb(bytes),
            detail: "Caches, Trash & DerivedData",
            score: score)
    }

    // MARK: Helpers

    /// Linear score between two anchor points, clamped to [10, 100]. `lo`/`hi` map
    /// to `loScore`/`hiScore`; `hi` may be below `lo` (inverse metrics like uptime).
    static func lerpScore(_ x: Double, lo: Double, hi: Double, loScore: Int, hiScore: Int) -> Int {
        guard lo != hi else { return hiScore }
        let t = (x - lo) / (hi - lo)
        let s = Double(loScore) + t * Double(hiScore - loScore)
        // Clamp to the score anchors so a metric never dips below its own floor.
        let lower = Double(min(loScore, hiScore)), upper = Double(max(loScore, hiScore))
        return Int(min(upper, max(lower, s)).rounded())
    }

    private static func gb(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_000_000_000
        if gb >= 10 { return "\(Int(gb.rounded())) GB" }
        if gb >= 1  { return String(format: "%.1f GB", gb) }
        return "\(Int((Double(bytes) / 1_000_000).rounded())) MB"
    }

    /// Total allocated size under a directory (best-effort; skips unreadable items).
    private static func directorySize(_ url: URL) -> Int64 {
        guard let en = FileManager.default.enumerator(
            at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles], errorHandler: { _, _ in true }) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in en {
            let vals = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey])
            if vals?.isRegularFile == true { total += Int64(vals?.totalFileAllocatedSize ?? 0) }
        }
        return total
    }
}
