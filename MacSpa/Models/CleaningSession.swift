import Foundation
import SwiftData

/// One completed or partial spa-cleaning session.
@Model
final class CleaningSession {
    var id: UUID
    var startDate: Date
    var duration: TimeInterval
    var devices: [String]          // stage titles, e.g. ["Keyboard Care", ...]
    var wellnessBefore: Int
    var wellnessAfter: Int
    var completed: Bool

    init(devices: [String], wellnessBefore: Int) {
        self.id = UUID()
        self.startDate = Date()
        self.duration = 0
        self.devices = devices
        self.wellnessBefore = wellnessBefore
        self.wellnessAfter = wellnessBefore
        self.completed = false
    }
}
