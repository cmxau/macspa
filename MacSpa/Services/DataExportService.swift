import AppKit
import SwiftData
import UniformTypeIdentifiers

/// Exports all locally-stored MacSpa data to a JSON file, and purges it on
/// request. Everything stays on-device - export is a user-initiated save to a
/// location they choose; nothing is ever transmitted.
@MainActor
enum DataExportService {

    // MARK: Codable snapshot

    private struct Snapshot: Codable {
        var exportedAt: Date
        var appVersion: String
        var sessions: [Session]
        var achievements: [Ach]
    }
    private struct Session: Codable {
        var startDate: Date, duration: TimeInterval, devices: [String]
        var wellnessBefore: Int, wellnessAfter: Int, completed: Bool
    }
    private struct Ach: Codable {
        var id: String, unlockedDate: Date?, progressValue: Double
    }

    // MARK: Export

    /// Gathers all data, then prompts for a save location and writes JSON.
    /// No-op if the user cancels the save panel.
    static func run(context: ModelContext) {
        guard let data = encode(context: context) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "MacSpa-Export-\(Self.stamp()).json"
        panel.title = "Export MacSpa Data"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? data.write(to: url)
    }

    private static func encode(context: ModelContext) -> Data? {
        let sessions = (try? context.fetch(FetchDescriptor<CleaningSession>())) ?? []
        let achs = (try? context.fetch(FetchDescriptor<Achievement>())) ?? []

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let snapshot = Snapshot(
            exportedAt: Date(),
            appVersion: version,
            sessions: sessions.map { Session(startDate: $0.startDate, duration: $0.duration,
                                             devices: $0.devices, wellnessBefore: $0.wellnessBefore,
                                             wellnessAfter: $0.wellnessAfter, completed: $0.completed) },
            achievements: achs.map { Ach(id: $0.id, unlockedDate: $0.unlockedDate, progressValue: $0.progressValue) }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(snapshot)
    }

    private static func stamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    // MARK: Purge

    /// Deletes every stored session and achievement. Irreversible.
    static func purgeAll(context: ModelContext) {
        for s in (try? context.fetch(FetchDescriptor<CleaningSession>())) ?? [] { context.delete(s) }
        for a in (try? context.fetch(FetchDescriptor<Achievement>())) ?? [] { context.delete(a) }
        try? context.save()
    }
}
