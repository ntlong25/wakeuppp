import XCTest
@testable import WakeMission

final class MathProblemGeneratorTests: XCTestCase {
    func testAnswersAreNonNegativeForAllDifficulties() {
        for difficulty in MissionDifficulty.allCases {
            for _ in 0..<2000 {
                XCTAssertGreaterThanOrEqual(MathProblemGenerator.generate(for: difficulty).answer, 0, "\(difficulty)")
            }
        }
    }

    func testRequiredCounts() {
        XCTAssertEqual(MathProblemGenerator.requiredCount(for: .easy), 2)
        XCTAssertEqual(MathProblemGenerator.requiredCount(for: .medium), 3)
        XCTAssertEqual(MathProblemGenerator.requiredCount(for: .hard), 4)
    }
}

final class TypingValidatorTests: XCTestCase {
    func testMatchIgnoresCaseAndExtraWhitespace() {
        XCTAssertTrue(TypingValidator.isMatch(input: "  trust   yourself. ", target: "Trust yourself."))
    }

    func testSmartQuotesAreNormalized() {
        XCTAssertTrue(TypingValidator.isMatch(input: "You don\u{2019}t", target: "You don't"))
    }

    func testMismatch() {
        XCTAssertFalse(TypingValidator.isMatch(input: "Trust yourself", target: "Trust yourself."))
    }

    func testPrefixLength() {
        XCTAssertEqual(TypingValidator.correctPrefixLength(input: "Trux", target: "Trust"), 3)
    }

    func testPasteIsSuspicious() {
        XCTAssertTrue(TypingValidator.isSuspiciousJump(old: "", new: "Trust yourself."))
        XCTAssertFalse(TypingValidator.isSuspiciousJump(old: "Tru", new: "Trus"))
        XCTAssertFalse(TypingValidator.isSuspiciousJump(old: "Trus", new: "Tru"))
    }

    func testAllPhrasesAreSelfMatching() {
        for d in MissionDifficulty.allCases {
            for p in TypingPhraseGenerator.phrases(for: d) {
                XCTAssertTrue(TypingValidator.isMatch(input: p, target: p))
            }
        }
    }
}

final class AlarmScheduleMathTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    func testOneShotLaterToday() {
        let now = date(2026, 1, 5, 6, 0)
        let next = AlarmScheduleMath.nextFireDate(time: date(2000, 1, 1, 7, 30), repeatDays: [], after: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 1, 5, 7, 30))
    }

    func testOneShotAlreadyPassedGoesToTomorrow() {
        let now = date(2026, 1, 5, 8, 0)
        let next = AlarmScheduleMath.nextFireDate(time: date(2000, 1, 1, 7, 30), repeatDays: [], after: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 1, 6, 7, 30))
    }

    func testAcrossMidnight() {
        let now = date(2026, 1, 5, 23, 59)
        let next = AlarmScheduleMath.nextFireDate(time: date(2000, 1, 1, 0, 1), repeatDays: [], after: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 1, 6, 0, 1))
    }

    func testRepeatPicksSoonestWeekday() {
        // 2026-01-05 is a Monday (weekday 2). Alarm on Wed(4) and Fri(6) -> Wed 2026-01-07.
        let now = date(2026, 1, 5, 12, 0)
        let next = AlarmScheduleMath.nextFireDate(time: date(2000, 1, 1, 7, 0), repeatDays: [6, 4], after: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 1, 7, 7, 0))
    }

    func testRepeatTodayIfStillAhead() {
        let now = date(2026, 1, 5, 6, 0) // Monday
        let next = AlarmScheduleMath.nextFireDate(time: date(2000, 1, 1, 7, 0), repeatDays: [2], after: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 1, 5, 7, 0))
    }

    func testCountdownText() {
        let now = date(2026, 1, 5, 6, 0)
        XCTAssertEqual(AlarmScheduleMath.countdownText(to: date(2026, 1, 5, 13, 42), from: now), "in 7h 42m")
        XCTAssertEqual(AlarmScheduleMath.countdownText(to: date(2026, 1, 5, 6, 12), from: now), "in 12m")
        XCTAssertEqual(AlarmScheduleMath.countdownText(to: date(2026, 1, 6, 8, 0), from: now), "in 1d 2h")
    }
}

final class StreakCalculatorTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func day(_ d: Int, hour: Int = 7) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 1, day: d, hour: hour))!
    }

    func testStreakCountsConsecutiveDaysIncludingToday() {
        let dates = [day(3), day(4), day(5)]
        XCTAssertEqual(StreakCalculator.currentStreak(successDates: dates, today: day(5, hour: 9), calendar: cal), 3)
    }

    func testStreakSurvivesUntilToday() {
        let dates = [day(3), day(4)]
        XCTAssertEqual(StreakCalculator.currentStreak(successDates: dates, today: day(5, hour: 5), calendar: cal), 2)
    }

    func testGapBreaksStreak() {
        let dates = [day(1), day(2), day(4)]
        XCTAssertEqual(StreakCalculator.currentStreak(successDates: dates, today: day(4), calendar: cal), 1)
    }

    func testNoSuccessIsZero() {
        XCTAssertEqual(StreakCalculator.currentStreak(successDates: [], today: day(5), calendar: cal), 0)
    }

    func testDailyCounts() {
        let counts = StreakCalculator.dailyCounts(successDates: [day(5), day(5, hour: 8), day(3)], days: 3, today: day(5), calendar: cal)
        XCTAssertEqual(counts.map(\.count), [1, 0, 2])
    }

    func testAverageTimeOfDay() {
        let avg = StreakCalculator.averageTimeOfDay([day(1, hour: 6), day(2, hour: 8)], calendar: cal)
        XCTAssertEqual(avg, 7 * 3600)
    }
}

final class PhotoMatchDeciderTests: XCTestCase {
    func testRequiresConsecutiveMatchesOnLiveFeed() {
        var d = PhotoMatchDecider(requiredConsecutive: 3, varianceWindow: 4, minLumaRange: 0.01)
        let lumas = [0.40, 0.42, 0.45, 0.43, 0.47, 0.44]
        var done = false
        for l in lumas { done = d.ingest(matched: true, luma: l) }
        XCTAssertTrue(done)
    }

    func testMissResetsStreak() {
        var d = PhotoMatchDecider(requiredConsecutive: 3, varianceWindow: 3, minLumaRange: 0.01)
        _ = d.ingest(matched: true, luma: 0.40)
        _ = d.ingest(matched: true, luma: 0.45)
        _ = d.ingest(matched: false, luma: 0.50)
        XCTAssertFalse(d.ingest(matched: true, luma: 0.41))
        XCTAssertEqual(d.consecutive, 1)
    }

    func testStaticFeedNeverCompletes() {
        var d = PhotoMatchDecider(requiredConsecutive: 3, varianceWindow: 4, minLumaRange: 0.01)
        var done = false
        for _ in 0..<50 { done = d.ingest(matched: true, luma: 0.5) || done }
        XCTAssertFalse(done)
    }

    func testThresholdsGetStricter() {
        XCTAssertGreaterThan(PhotoThreshold.maxDistance(for: .easy), PhotoThreshold.maxDistance(for: .medium))
        XCTAssertGreaterThan(PhotoThreshold.maxDistance(for: .medium), PhotoThreshold.maxDistance(for: .hard))
    }

    func testSimilarityClamped() {
        XCTAssertEqual(PhotoThreshold.similarity(distance: 0, threshold: 0.5), 1)
        XCTAssertEqual(PhotoThreshold.similarity(distance: 5, threshold: 0.5), 0)
    }
}

final class RingingStoreTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let name = "RingingStoreTests-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    func testBeginIsIdempotentForSameAlarm() {
        let d = makeDefaults()
        let id = UUID()
        XCTAssertTrue(RingingStore.begin(alarmId: id, defaults: d))
        XCTAssertFalse(RingingStore.begin(alarmId: id, defaults: d))
        XCTAssertEqual(RingingStore.current(defaults: d)?.alarmId, id)
    }

    func testStaleSessionIsDiscarded() {
        let d = makeDefaults()
        let id = UUID()
        let start = Date()
        RingingStore.begin(alarmId: id, now: start, defaults: d)
        XCTAssertNil(RingingStore.current(now: start.addingTimeInterval(RingingStore.maxAge + 1), defaults: d))
        XCTAssertNil(RingingStore.current(now: start, defaults: d))
    }

    func testClear() {
        let d = makeDefaults()
        RingingStore.begin(alarmId: UUID(), defaults: d)
        RingingStore.clear(defaults: d)
        XCTAssertNil(RingingStore.current(defaults: d))
    }
}
