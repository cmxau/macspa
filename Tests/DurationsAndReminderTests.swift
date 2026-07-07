import XCTest
@testable import MacSpa

final class CleaningDurationsTests: XCTestCase {
    func testLabelFormatting() {
        XCTAssertEqual(CleaningDurations.label(45), "45s")
        XCTAssertEqual(CleaningDurations.label(30), "30s")
        XCTAssertEqual(CleaningDurations.label(60), "1 min")
        XCTAssertEqual(CleaningDurations.label(90), "1m 30s")
        XCTAssertEqual(CleaningDurations.label(120), "2 min")
        XCTAssertEqual(CleaningDurations.label(125), "2m 5s")
    }

    func testDefaultsInRange() {
        for d in [CleaningDurations.defaultKeyboard, CleaningDurations.defaultTrackpad, CleaningDurations.defaultDisplay] {
            XCTAssertTrue(CleaningDurations.range.contains(d))
        }
    }
}

final class ReminderServiceTests: XCTestCase {
    private let cal = Calendar.current

    override func setUp() {
        super.setUp()
        UserDefaults.standard.set(true, forKey: "reminderEnabled")
    }

    func testWeeklyNextIsFutureSundayAtTen() {
        UserDefaults.standard.set("weekly", forKey: "reminderSchedule")
        let next = ReminderService.nextDate()
        XCTAssertNotNil(next)
        guard let next else { return }
        XCTAssertGreaterThan(next, Date())
        XCTAssertEqual(cal.component(.weekday, from: next), 1)   // Sunday
        XCTAssertEqual(cal.component(.hour, from: next), 10)
        XCTAssertEqual(cal.component(.minute, from: next), 0)
    }

    func testMonthlyNextIsFirstSunday() {
        UserDefaults.standard.set("monthly", forKey: "reminderSchedule")
        let next = ReminderService.nextDate()
        XCTAssertNotNil(next)
        guard let next else { return }
        XCTAssertEqual(cal.component(.weekday, from: next), 1)   // Sunday
        XCTAssertLessThanOrEqual(cal.component(.day, from: next), 7)   // first week → first Sunday
        XCTAssertEqual(cal.component(.hour, from: next), 10)
    }

    func testBiweeklyNextIsFutureSunday() {
        UserDefaults.standard.set("biweekly", forKey: "reminderSchedule")
        let next = ReminderService.nextDate()
        XCTAssertNotNil(next)
        guard let next else { return }
        XCTAssertGreaterThan(next, Date())
        XCTAssertEqual(cal.component(.weekday, from: next), 1)
        XCTAssertEqual(cal.component(.hour, from: next), 10)
    }

    func testDisabledReturnsNil() {
        UserDefaults.standard.set(false, forKey: "reminderEnabled")
        XCTAssertNil(ReminderService.nextDate())
    }
}
