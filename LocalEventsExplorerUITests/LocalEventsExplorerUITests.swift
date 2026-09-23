//
//  LocalEventsExplorerUITests.swift
//  LocalEventsExplorerUITests
//
//  Created by Navdeep Rana on 23/09/26.
//

import XCTest

final class LocalEventsExplorerUITests: XCTestCase {

    func test_launch_showsEventsScreen() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
    }
}
