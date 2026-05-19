import XCTest

final class BrainfitUITests: XCTestCase {
    func testHomeScreenShowsStartButton() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Start dagens trening"].waitForExistence(timeout: 5))
    }

    func testCanNavigateBetweenTabs() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Statistikk"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Statistikk"].tap()
        XCTAssertTrue(app.staticTexts["Snittscore per dag"].exists ||
                      app.staticTexts["Ingen data ennå — spill noen økter først."].exists)
        app.tabBars.buttons["Innstillinger"].tap()
        XCTAssertTrue(app.navigationBars["Innstillinger"].exists)
    }

    func testCancelSessionReturnsToHome() {
        let app = XCUIApplication()
        app.launch()
        guard app.buttons["Start dagens trening"].waitForExistence(timeout: 5) else {
            return XCTFail("Start-knapp ikke funnet")
        }
        app.buttons["Start dagens trening"].tap()
        XCTAssertTrue(app.buttons["Avbryt økt"].waitForExistence(timeout: 5))
        app.buttons["Avbryt økt"].tap()
        app.buttons["Avbryt økten"].tap()
        XCTAssertTrue(app.buttons["Start dagens trening"].waitForExistence(timeout: 5))
    }
}
