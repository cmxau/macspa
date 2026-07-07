import XCTest
@testable import MacSpa

final class WellnessServiceTests: XCTestCase {
    private let svc = WellnessService.shared

    private func session(daysAgo: Int) -> CleaningSession {
        let s = CleaningSession(devices: ["Keyboard Care"], wellnessBefore: 0)
        s.startDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return s
    }

    // MARK: score

    func testEmptyHistoryScoresZero() {
        XCTAssertEqual(svc.score(sessions: []), 0)
        XCTAssertNil(svc.daysSinceLast([]))
    }

    func testFreshCleanScoresHigh() {
        // Cleaned today → full recency (80) + some frequency.
        let score = svc.score(sessions: [session(daysAgo: 0)])
        XCTAssertGreaterThanOrEqual(score, 80)
        XCTAssertLessThanOrEqual(score, 100)
    }

    func testScoreDecaysWithTime() {
        let recent = svc.score(sessions: [session(daysAgo: 1)])
        let stale  = svc.score(sessions: [session(daysAgo: 40)])
        XCTAssertGreaterThan(recent, stale)
    }

    func testFrequencyCaps() {
        // Ten recent sessions: frequency component is capped at 20.
        let many = (0..<10).map { session(daysAgo: $0) }
        XCTAssertLessThanOrEqual(svc.score(sessions: many), 100)
    }

    func testDaysSinceLastUsesMostRecent() {
        let sessions = [session(daysAgo: 10), session(daysAgo: 3), session(daysAgo: 30)]
        XCTAssertEqual(svc.daysSinceLast(sessions), 3)
    }

    // MARK: mood - boundary conditions (the bit most likely to regress)

    func testMoodBoundaries() {
        XCTAssertEqual(svc.mood(score: 100), .fresh)
        XCTAssertEqual(svc.mood(score: 85), .fresh)
        XCTAssertEqual(svc.mood(score: 84), .happy)
        XCTAssertEqual(svc.mood(score: 65), .happy)
        XCTAssertEqual(svc.mood(score: 64), .dusty)
        XCTAssertEqual(svc.mood(score: 45), .dusty)
        XCTAssertEqual(svc.mood(score: 44), .needsAttention)
        XCTAssertEqual(svc.mood(score: 25), .needsAttention)
        XCTAssertEqual(svc.mood(score: 24), .sendHelp)
        XCTAssertEqual(svc.mood(score: 0), .sendHelp)
    }

    func testBandBoundaries() {
        XCTAssertEqual(svc.band(score: 90), "Pristine")
        XCTAssertEqual(svc.band(score: 70), "Fresh")
        XCTAssertEqual(svc.band(score: 50), "Okay")
        XCTAssertEqual(svc.band(score: 30), "Dusty")
        XCTAssertEqual(svc.band(score: 10), "Needs care")
    }
}
