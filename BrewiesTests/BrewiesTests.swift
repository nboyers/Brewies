//
//  BrewiesTests.swift
//  BrewiesTests
//
//  Created by Noah Boyers on 4/14/23.
//

//import XCTest
//@testable import Brewies
//import GoogleMobileAdsTarget
//
//final class BrewiesTests: XCTestCase {
//    var yelpAPI: YelpAPI!
//    private lazy var undesiredCatagories : Set<String> = [ "wine_bars", "bars", "pizza",
//                                                           "servicestations","hotdogs","burgers",
//                                                           "donuts","caribbean","seafood",
//                                                           "irish_pubs", "sandwiches","tradamerican",
//                                                           "italian","desserts","vapeshops",
//                                                           "salad","newamerican","breakfast_brunch"
//    ]
//    
//    override func setUpWithError() throws {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//        super.setUp()
//        yelpAPI = YelpAPI(yelpParams: <#YelpSearchParams#>)
//    }
//    
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        yelpAPI = nil
//        super.tearDown()
//    }
//    
////    func testIsExcludedChain() {
////        XCTAssertTrue(yelpAPI.isExcludedChain(name: "Starbucks", categories: undesiredCatagories))
////        XCTAssertFalse(yelpAPI.isExcludedChain(name: "My Local Coffee Shop", categories: undesiredCatagories))
////    }
////    
//    
//    func testFetchIndependentCoffeeShops() {
//        let expectation = XCTestExpectation(description: "Fetch independent coffee shops")
//        
//        yelpAPI.fetchIndependentCoffeeShops(
//            latitude: 27.814343,
//            longitude: -82.780275
//        ) { coffeeShops in
//            XCTAssertFalse(coffeeShops.isEmpty)
//            expectation.fulfill()
//        }
//        
//        wait(for: [expectation], timeout: 10.0)
//    }
//}
