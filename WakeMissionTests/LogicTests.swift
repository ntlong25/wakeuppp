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
