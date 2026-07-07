import XCTest
@testable import MacSpa

final class SystemHealthTests: XCTestCase {

    // MARK: lerpScore - the mapping every metric relies on

    func testAscendingMetricClampsAndInterpolates() {
        // lo=0.05 → 10, hi=0.30 → 100 (e.g. storage free fraction).
        XCTAssertEqual(SystemHealthService.lerpScore(0.30, lo: 0.05, hi: 0.30, loScore: 10, hiScore: 100), 100)
        XCTAssertEqual(SystemHealthService.lerpScore(0.05, lo: 0.05, hi: 0.30, loScore: 10, hiScore: 100), 10)
        // Below/above the anchors clamp, never exceeding [10, 100].
        XCTAssertEqual(SystemHealthService.lerpScore(0.0,  lo: 0.05, hi: 0.30, loScore: 10, hiScore: 100), 10)
        XCTAssertEqual(SystemHealthService.lerpScore(0.9,  lo: 0.05, hi: 0.30, loScore: 10, hiScore: 100), 100)
        // Midpoint interpolates.
        let mid = SystemHealthService.lerpScore(0.175, lo: 0.05, hi: 0.30, loScore: 10, hiScore: 100)
        XCTAssertEqual(mid, 55, accuracy: 1)
    }

    func testInverseMetric() {
        // hi below lo (e.g. uptime: 2 days → 100, 14 days → 30).
        XCTAssertEqual(SystemHealthService.lerpScore(2,  lo: 14, hi: 2, loScore: 30, hiScore: 100), 100)
        XCTAssertEqual(SystemHealthService.lerpScore(14, lo: 14, hi: 2, loScore: 30, hiScore: 100), 30)
        XCTAssertEqual(SystemHealthService.lerpScore(30, lo: 14, hi: 2, loScore: 30, hiScore: 100), 30) // older clamps low
        XCTAssertEqual(SystemHealthService.lerpScore(0,  lo: 14, hi: 2, loScore: 30, hiScore: 100), 100) // fresher clamps high
    }

    func testAlwaysWithinBounds() {
        for x in stride(from: -5.0, through: 100.0, by: 3.3) {
            let s = SystemHealthService.lerpScore(x, lo: 1, hi: 25, loScore: 30, hiScore: 100)
            XCTAssertGreaterThanOrEqual(s, 10)
            XCTAssertLessThanOrEqual(s, 100)
        }
    }

    // MARK: live snapshot is sane on this machine

    func testSnapshotProducesScoredMetrics() async {
        let snap = await SystemHealthService.snapshot()
        XCTAssertFalse(snap.metrics.isEmpty)
        XCTAssertTrue((0...100).contains(snap.score))
        for m in snap.metrics { XCTAssertTrue((0...100).contains(m.score), "\(m.id) out of range") }
        // Storage, memory, uptime and junk are always present (battery may be absent).
        XCTAssertTrue(snap.metrics.contains { $0.id == "storage" })
        XCTAssertTrue(snap.metrics.contains { $0.id == "uptime" })
    }
}
