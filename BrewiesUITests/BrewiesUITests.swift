//
//  BrewiesUITests.swift
//  BrewiesUITests
//
//  Created by Noah Boyers on 4/14/23.
//

import XCTest

final class BrewiesUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        // This setup will be done before each test method is invoked.
        app.launchArguments += ["UI-Testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        // This teardown will be done after each test method is invoked.
        app.terminate()
    }

    func testExample() throws {
        // Write any specific UI tests here. For example, you can test if the first screen is displaying the correct elements:
        XCTAssertTrue(app.buttons["Search Area"].exists) // Replace "SomeButton" with the accessibility identifier of a button in your app.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
