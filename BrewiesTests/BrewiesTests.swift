//
//  BrewiesTests.swift
//  BrewiesTests
//
//  Created by Noah Boyers on 4/14/23.
//

import XCTest
@testable import Brewies
import GoogleMobileAdsTarget

final class BrewiesTests: XCTestCase {
    var yelpAPI: YelpAPI!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        yelpAPI = YelpAPI()
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        yelpAPI = nil
        super.tearDown()
    }
    
    func testIsExcludedChain() {
        XCTAssertTrue(yelpAPI.isExcludedChain(name: "Starbucks"))
        XCTAssertFalse(yelpAPI.isExcludedChain(name: "My Local Coffee Shop"))
    }
    
    
    func testFetchIndependentCoffeeShops() {
        let expectation = XCTestExpectation(description: "Fetch independent coffee shops")

        yelpAPI.fetchIndependentCoffeeShops(
            latitude: 27.814343,
            longitude: -82.780275
        ) { coffeeShops in
            XCTAssertFalse(coffeeShops.isEmpty)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }
}
