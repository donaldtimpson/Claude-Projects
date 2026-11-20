import XCTest

// Plays a duel from both ends: each side picks a challenge and readies up, then rounds won from
// the bottom, from the (upside-down) top, a wrong tap that locks a player out, both sides pressing
// back to back, and on to the victory screen and a rematch. Saves screenshots to SCREENSHOT_DIR
// when set (mid-duel, lockout, victory).
final class DuelTests: XCTestCase {
    private var app: XCUIApplication!

    func testDuelBothSides() throws {
        app = XCUIApplication()
        app.launchEnvironment = ["LUDUS_MUTE": "1", "LUDUS_SCREEN": "duel", "LUDUS_DUEL_SEED": "7"]
        if let o = ProcessInfo.processInfo.environment["DUEL_ORIENT"], o == "landscape" {
            XCUIDevice.shared.orientation = .landscapeLeft
        } else {
            XCUIDevice.shared.orientation = .portrait
        }
        app.launch()

        // Setup: different challenges at each end, then both ready.
        el("duel.top.level.Consul").tap()
        el("duel.bottom.level.Tiro").tap()
        el("duel.bottom.ready").tap()
        el("duel.top.ready").tap()
        XCTAssertTrue(el("duel.bottom.answer.right").waitForExistence(timeout: 6), "no questions after the countdown")

        // Round 1: the bottom player.
        el("duel.bottom.answer.right").tap()
        XCTAssertTrue(el("duel.bottom.point").waitForExistence(timeout: 2))
        XCTAssertTrue(el("duel.top.slow").exists, "the other side should hear it was too slow")
        save("1-point-bottom")
        XCTAssertEqual(score(.bottom), 1)
        nextRound()

        // Round 2: the top player (its half is upside down; taps must still land).
        el("duel.top.answer.right").tap()
        XCTAssertTrue(el("duel.top.point").waitForExistence(timeout: 2))
        XCTAssertEqual(score(.top), 1)
        nextRound()

        // Round 3: a wrong tap locks the top out; its right answer is ignored meanwhile, and the
        // bottom takes the point.
        el("duel.top.answer.wrong", prefix: true).tap()
        el("duel.top.answer.right").tap()
        save("2-lockout")
        XCTAssertFalse(el("duel.top.point").exists, "a locked-out player must not score")
        el("duel.bottom.answer.right").tap()
        XCTAssertTrue(el("duel.bottom.point").waitForExistence(timeout: 2))
        XCTAssertEqual(score(.top), 1)
        XCTAssertEqual(score(.bottom), 2)
        nextRound()

        // Round 4: both press their right answers back to back — exactly one point is given.
        el("duel.top.answer.right").tap()
        el("duel.bottom.answer.right").tap()
        // (XCUITest's taps are a second or so apart, so the round may already have moved on: check
        // the tally rather than the "+1" flag.)
        XCTAssertEqual(score(.top), 2, "the first right answer takes the round")
        XCTAssertEqual(score(.bottom), 2, "the second press, in the same round, scores nothing")
        nextRound()
        save("3-mid-duel")

        // On to the win (first to 7) from the bottom.
        while score(.bottom) < 7 {
            el("duel.bottom.answer.right").tap()
            XCTAssertTrue(el("duel.bottom.point").waitForExistence(timeout: 2))
            if score(.bottom) < 7 { nextRound() }
        }
        XCTAssertTrue(el("duel.bottom.rematch").waitForExistence(timeout: 4), "no victory screen")
        XCTAssertTrue(el("duel.top.rematch").exists)
        sleep(1)
        save("4-victory")

        // Rematch: back to the challenge picker, scores cleared, each side must ready again.
        el("duel.top.rematch").tap()
        XCTAssertTrue(el("duel.bottom.ready").waitForExistence(timeout: 2))
        XCTAssertTrue(el("duel.top.level.Consul").exists)
    }

    private enum End { case top, bottom }

    private func el(_ id: String, prefix: Bool = false) -> XCUIElement {
        let q = app.descendants(matching: .any)
        return prefix ? q.matching(NSPredicate(format: "identifier BEGINSWITH %@", id)).firstMatch : q[id]
    }

    private func score(_ end: End) -> Int {
        let e = el(end == .top ? "duel.top.score" : "duel.bottom.score")
        _ = e.waitForExistence(timeout: 2)
        return Int(e.label) ?? -1
    }

    /// Waits out the between-rounds pause until fresh questions are up.
    private func nextRound() {
        let gone = NSPredicate(format: "exists == false")
        for id in ["duel.top.point", "duel.bottom.point"] {
            let x = expectation(for: gone, evaluatedWith: el(id))
            wait(for: [x], timeout: 4)
        }
    }

    private func save(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(screenshot: shot)
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }
}
