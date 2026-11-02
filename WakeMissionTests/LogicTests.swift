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
        for language in ["en", "vi"] {
            for d in MissionDifficulty.allCases {
                for p in TypingPhraseGenerator.phrases(for: d, language: language) {
                    XCTAssertTrue(TypingValidator.isMatch(input: p, target: p))
                }
            }
        }
    }

    func testVietnameseCanBeTypedWithoutAccents() {
        XCTAssertTrue(TypingValidator.isMatch(input: "day thoi nao.", target: "Dậy thôi nào."))
        XCTAssertTrue(TypingValidator.isMatch(input: "dung doi", target: "Đừng đợi"))
    }

    func testAccentFoldingKeepsPrefixAlignedWithTarget() {
        let target = "Dậy thôi"
        XCTAssertEqual(TypingValidator.normalize(target).count, target.count)
        XCTAssertEqual(TypingValidator.correctPrefixLength(input: "day", target: target), 3)
    }

    func testPhrasesFollowLanguage() {
        XCTAssertEqual(TypingPhraseGenerator.phrases(for: .easy, language: "vi"), TypingPhraseGenerator.easyPhrasesVI)
        XCTAssertEqual(TypingPhraseGenerator.phrases(for: .easy, language: "en"), TypingPhraseGenerator.easyPhrases)
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
        let next = AlarmScheduleMath.nextFireDate(hour: 7, minute: 30, repeatDays: [], after: date(2026, 1, 5, 6, 0), calendar: cal)
        XCTAssertEqual(next, date(2026, 1, 5, 7, 30))
    }

    func testOneShotAlreadyPassedGoesToTomorrow() {
        let next = AlarmScheduleMath.nextFireDate(hour: 7, minute: 30, repeatDays: [], after: date(2026, 1, 5, 8, 0), calendar: cal)
        XCTAssertEqual(next, date(2026, 1, 6, 7, 30))
    }

    func testAcrossMidnight() {
        let next = AlarmScheduleMath.nextFireDate(hour: 0, minute: 1, repeatDays: [], after: date(2026, 1, 5, 23, 59), calendar: cal)
        XCTAssertEqual(next, date(2026, 1, 6, 0, 1))
    }

    func testRepeatPicksSoonestWeekday() {
        // 2026-01-05 is a Monday. Wed(4) and Fri(6) -> Wed 2026-01-07.
        let next = AlarmScheduleMath.nextFireDate(hour: 7, minute: 0, repeatDays: [6, 4], after: date(2026, 1, 5, 12, 0), calendar: cal)
        XCTAssertEqual(next, date(2026, 1, 7, 7, 0))
    }

    func testRepeatTodayIfStillAhead() {
        let next = AlarmScheduleMath.nextFireDate(hour: 7, minute: 0, repeatDays: [2], after: date(2026, 1, 5, 6, 0), calendar: cal)
        XCTAssertEqual(next, date(2026, 1, 5, 7, 0))
    }
}

final class AlarmEntryTests: XCTestCase {
    func testOneShotExpiresAfterItsFireDate() {
        let fire = Date()
        let alarm = AlarmEntry(hour: 7, minute: 0, oneShotFireDate: fire)
        XCTAssertFalse(alarm.isExpired(now: fire.addingTimeInterval(-1)))
        XCTAssertTrue(alarm.isExpired(now: fire.addingTimeInterval(1)))
    }

    func testRepeatingAlarmNeverExpires() {
        let alarm = AlarmEntry(hour: 7, minute: 0, repeatDays: [2], oneShotFireDate: Date.distantPast)
        XCTAssertFalse(alarm.isExpired())
    }

    func testDisabledAlarmIsNotExpired() {
        let alarm = AlarmEntry(hour: 7, minute: 0, isEnabled: false, oneShotFireDate: Date.distantPast)
        XCTAssertFalse(alarm.isExpired())
    }

    func testWeekOrderStartsOnFirstWeekday() {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        XCTAssertEqual(AlarmEntry.weekOrder(calendar: cal), [2, 3, 4, 5, 6, 7, 1])
    }

    func testCodableRoundTrip() throws {
        let alarm = AlarmEntry(hour: 6, minute: 45, label: "Gym", repeatDays: [2, 4])
        let decoded = try JSONDecoder().decode(AlarmEntry.self, from: JSONEncoder().encode(alarm))
        XCTAssertEqual(decoded, alarm)
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

    func testBeginIsIdempotentWhileSessionActive() {
        let d = makeDefaults()
        XCTAssertTrue(RingingStore.begin(defaults: d))
        XCTAssertFalse(RingingStore.begin(defaults: d))
        XCTAssertNotNil(RingingStore.current(defaults: d))
    }

    func testStaleSessionIsDiscarded() {
        let d = makeDefaults()
        let start = Date()
        RingingStore.begin(now: start, defaults: d)
        XCTAssertNil(RingingStore.current(now: start.addingTimeInterval(RingingStore.maxAge + 1), defaults: d))
        XCTAssertNil(RingingStore.current(now: start, defaults: d))
    }

    func testClear() {
        let d = makeDefaults()
        RingingStore.begin(defaults: d)
        RingingStore.clear(defaults: d)
        XCTAssertNil(RingingStore.current(defaults: d))
    }

    func testPendingIdsRoundTrip() {
        let d = makeDefaults()
        RingingStore.begin(defaults: d)
        let id = UUID()
        var session = RingingStore.current(defaults: d)!
        session.pendingAlarmIds = [id]
        RingingStore.save(session, defaults: d)
        XCTAssertEqual(RingingStore.current(defaults: d)?.pendingAlarmIds, [id])
    }
}

final class WakeSettingsTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let name = "WakeSettingsTests-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    func testDefaultsWhenNothingSaved() {
        XCTAssertEqual(WakeSettings.load(defaults: makeDefaults()), .default)
    }

    func testRoundTrip() {
        let d = makeDefaults()
        var s = WakeSettings.default
        s.ringMode = .continuous
        s.missions.append(MissionDraft(type: .photo, difficulty: .hard, configurationData: Data([1, 2, 3])))
        s.save(defaults: d)
        XCTAssertEqual(WakeSettings.load(defaults: d), s)
    }

    func testRearmDelays() {
        XCTAssertEqual(RingMode.every5.rearmDelay, 5)
        XCTAssertEqual(RingMode.every60.rearmDelay, 60)
        XCTAssertEqual(RingMode.continuous.rearmDelay, 2)
        XCTAssertEqual(WakeSettings.default.ringMode, .every5)
    }
}
