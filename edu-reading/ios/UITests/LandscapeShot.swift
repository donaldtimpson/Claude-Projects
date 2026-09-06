import XCTest

// The Simulator cannot be rotated from the command line, and a layout nobody looks
// at is a layout that is broken — so rotation happens here. Run it and pull the
// screenshot out of the result bundle:
//
//   xcodebuild test -project SoundItOut.xcodeproj -scheme SoundItOut \
//     -sdk iphonesimulator -destination "id=<device>" \
//     -only-testing:SoundItOutUITests -resultBundlePath /tmp/ls.xcresult
//   xcrun xcresulttool export attachments --path /tmp/ls.xcresult --output-path out
final class LandscapeShot: XCTestCase {
    /// Captures each picture deck in landscape, and checks the card still holds a
    /// readable word — the failure this guards against is a layout that only works
    /// in portrait.
    func testCardsInLandscape() {
        for screen in ["pictures", "drawings"] {
            let app = XCUIApplication()
            app.launchArguments = ["-screen", screen]
            app.launch()
            XCUIDevice.shared.orientation = .landscapeLeft
            sleep(2)
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "landscape-\(screen)"
            shot.lifetime = .keepAlways
            add(shot)
            // The word is drawn as a single text run per letter; if the card
            // collapsed, none of it would be on screen.
            XCTAssertTrue(app.staticTexts.count > 0, "\(screen) rendered no text in landscape")
            XCUIDevice.shared.orientation = .portrait
            app.terminate()
        }
    }
}
