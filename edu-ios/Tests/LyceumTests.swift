import XCTest
@testable import Lyceum

final class LyceumTests: XCTestCase {

    func testArithmeticDrillProducesSolvableNumericProblems() {
        for _ in 0..<100 {
            let problem = DrillCatalog.arithmetic.generate(2)
            guard case let .numeric(answer, unit) = problem.input else {
                return XCTFail("arithmetic drill should produce a numeric problem")
            }
            XCTAssertNil(unit, "arithmetic answers are bare integers")
            XCTAssertGreaterThan(abs(answer), 0)
            XCTAssertFalse(problem.prompt.isEmpty)
        }
    }

    func testUnitCircleChoiceIndexIsValid() {
        for _ in 0..<100 {
            let problem = DrillCatalog.unitCircle.generate(1)
            guard case let .choice(options, index) = problem.input else {
                return XCTFail("unit-circle drill should produce a choice problem")
            }
            XCTAssertTrue(options.indices.contains(index))
        }
    }

    // The vectors drill asks for ONE component as multiple choice (it used to take both x and
    // y as typed fields, which is what this test was written against and why it stopped
    // compiling). Every option must be a distinct exact value with the answer among them.
    func testVectorComponentsAreDistinctExactChoices() {
        for _ in 0..<50 {
            let problem = DrillCatalog.vectors.generate(2)
            guard case let .choice(options, index) = problem.input else {
                return XCTFail("vectors drill should produce a choice problem")
            }
            XCTAssertEqual(options.count, 4)
            XCTAssertTrue(options.indices.contains(index))
            XCTAssertEqual(Set(options).count, options.count, "options must not repeat: \(options)")
            XCTAssertFalse(problem.prompt.isEmpty)
        }
    }

    func testClientIdIsUnique() {
        XCTAssertNotEqual(makeClientId(), makeClientId())
    }

    func testCourseListItemDecoding() throws {
        let json = Data("""
        {"id":"c1","title":"Calculus","description":"","thumbnailUrl":"",
         "videoCount":3,"isCurrent":true,"updatedAt":"2026-01-01T00:00:00Z"}
        """.utf8)
        let course = try JSONDecoder().decode(CourseListItem.self, from: json)
        XCTAssertEqual(course.id, "c1")
        XCTAssertEqual(course.videoCount, 3)
        XCTAssertTrue(course.isCurrent)
    }

    func testWriteResultDecoding() throws {
        let json = Data(#"{"duplicate":false,"badges":[]}"#.utf8)
        let result = try JSONDecoder().decode(WriteResult.self, from: json)
        XCTAssertFalse(result.duplicate)
        XCTAssertTrue(result.badges.isEmpty)
    }

    // Regression: Learn has to keep reaching new material on a large pool. Restoring every
    // partially-known item as a "learning" card used to fill the introduction cap on the very
    // first card of a resumed session, so a big deck (Hard) re-drilled only the handful already
    // started on Easy and introduced nothing new — 1, 4, then 0 new items over 360 simulated cards.
    @MainActor
    func testLearnIntroducesNewItemsOnAResumedLargePool() {
        let user = "test-learn-resume", slug = "grammar-gauntlet"
        guard let def = DrillCatalog.drill(slug: slug), let pool = def.poolItems?(3), pool.count > 100 else {
            return XCTFail("expected a large Learn pool for \(slug)")
        }
        let mastery = DrillMastery.shared
        mastery.purgeAll()
        defer { mastery.purgeAll() }

        // Prior sessions left 20 items partially known — the state that used to starve the queue.
        let known = Set(pool.prefix(20))
        for id in known { mastery.grade(userId: user, slug: slug, item: id, correct: true) }

        let session = LearnSession(userId: user, slug: slug, items: pool)
        var introduced = Set<String>()
        for _ in 0..<120 {
            guard let id = session.next() else { return XCTFail("Learn session ended; it should not") }
            if !known.contains(id) { introduced.insert(id) }
            session.grade(correct: true)
        }
        XCTAssertGreaterThan(introduced.count, 5,
                             "Learn introduced only \(introduced.count) new items in 120 cards")
    }

    // The bar reads partial credit, so it moves on every correct answer rather than once per
    // five. On a 601-item pool, mastered-only progress sits at 0 long enough to look broken.
    @MainActor
    func testMasteryProgressGivesPartialCredit() {
        let user = "test-progress", slug = "lesson-01"
        let mastery = DrillMastery.shared
        mastery.purgeAll()
        defer { mastery.purgeAll() }

        let items = ["a", "b", "c", "d"]
        XCTAssertEqual(mastery.progress(userId: user, slug: slug, items: items), 0)
        mastery.grade(userId: user, slug: slug, item: "a", correct: true)   // box 1 of 5, 1 of 4 items
        XCTAssertEqual(mastery.progress(userId: user, slug: slug, items: items), 1.0 / 20.0, accuracy: 1e-9)
        XCTAssertEqual(mastery.masteredCount(userId: user, slug: slug, items: items), 0)

        for _ in 0..<4 { mastery.grade(userId: user, slug: slug, item: "a", correct: true) }
        XCTAssertEqual(mastery.progress(userId: user, slug: slug, items: items), 5.0 / 20.0, accuracy: 1e-9)
        XCTAssertEqual(mastery.masteredCount(userId: user, slug: slug, items: items), 1)
    }
}
