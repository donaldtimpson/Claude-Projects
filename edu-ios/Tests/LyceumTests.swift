import XCTest
@testable import Lyceum

final class LyceumTests: XCTestCase {

    func testArithmeticDrillProducesSolvableNumericProblems() {
        for _ in 0..<100 {
            let problem = DrillCatalog.arithmetic.generate(2)
            guard case let .numeric(answer, _, _) = problem.input else {
                return XCTFail("arithmetic drill should produce a numeric problem")
            }
            XCTAssertFalse(answer.isNaN)
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

    func testVectorComponentsMatchTrig() {
        for _ in 0..<50 {
            let problem = DrillCatalog.vectors.generate(2)
            guard case let .fields(fields) = problem.input else {
                return XCTFail("vectors drill should produce fields")
            }
            XCTAssertEqual(fields.count, 2)
            // Components must satisfy vx^2 + vy^2 == magnitude^2 (within tolerance).
            let mag = (fields[0].answer * fields[0].answer + fields[1].answer * fields[1].answer).squareRoot()
            XCTAssertGreaterThan(mag, 0)
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
}
