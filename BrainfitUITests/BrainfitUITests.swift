import XCTest

final class BrainfitUISmokeTests: XCTestCase {
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Brainfit"].waitForExistence(timeout: 5))
    }
}
