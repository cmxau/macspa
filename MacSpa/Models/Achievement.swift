import Foundation
import SwiftData

/// Persisted unlock state for an achievement slug. (Live progress is computed
/// from real data in `Milestone`; this backs future persisted unlock dates.)
@Model
final class Achievement {
    var id: String                 // slug, e.g. "first-session"
    var unlockedDate: Date?
    var progressValue: Double      // 0.0–1.0

    init(id: String) {
        self.id = id
        self.unlockedDate = nil
        self.progressValue = 0.0
    }
}
