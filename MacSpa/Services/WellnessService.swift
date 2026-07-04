// WellnessService.swift
import Foundation

/// Computes a device-wellness score purely from real cleaning history.
///
/// Score (0–100) = recency (0–80, decays since the last session) +
/// frequency (0–20, sessions in the last 90 days). Cleaning is infrequent, so
/// there is deliberately no daily-streak component.
final class WellnessService: Sendable {
    static let shared = WellnessService()

    /// Days since the most recent session, or nil if there are none.
    func daysSinceLast(_ sessions: [CleaningSession]) -> Int? {
        guard let last = sessions.map({ $0.startDate }).max() else { return nil }
        return max(0, Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0)
    }

    func score(sessions: [CleaningSession]) -> Int {
        guard let days = daysSinceLast(sessions) else { return 0 }
        // Recency: 80 right after a clean, decaying over the following weeks.
        let recency = 80.0 * exp(-Double(days) / 18.0)
        // Frequency: reward recent consistency.
        let now = Date()
        let last90 = sessions.filter {
            (Calendar.current.dateComponents([.day], from: $0.startDate, to: now).day ?? 999) <= 90
        }.count
        let frequency = min(20.0, Double(last90) * 4.0)
        return max(0, min(100, Int((recency + frequency).rounded())))
    }

    func mood(score: Int) -> DeviceMood {
        switch score {
        case 85...100: return .fresh
        case 65..<85:  return .happy
        case 45..<65:  return .dusty
        case 25..<45:  return .needsAttention
        default:       return .sendHelp
        }
    }

    /// Short care-level word for the score.
    func band(score: Int) -> String {
        switch score {
        case 85...100: return "Pristine"
        case 65..<85:  return "Fresh"
        case 45..<65:  return "Okay"
        case 25..<45:  return "Dusty"
        default:       return "Needs care"
        }
    }

    /// Human "in 2 days" / "3 days ago" style text.
    static func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f.localizedString(for: date, relativeTo: Date())
    }
}
