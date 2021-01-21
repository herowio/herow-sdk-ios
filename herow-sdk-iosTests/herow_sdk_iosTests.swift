//
//  herow_sdk_iosTests.swift
//  herow-sdk-iosTests
//
//  Created by Damien on 14/01/2021.
//

import XCTest
@testable import herow_sdk_ios

class herow_sdk_iosTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testCredentials() throws {
        let bundleBeingTested = Bundle(identifier: "io.herow.sdk.herow-sdk-ios")!
        ////If your plist contain root as Dictionary

        guard let path = bundleBeingTested.path(forResource: "platform-secrets", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) as? [String: [String:String]] else {
            print("no file")
            XCTAssertTrue(false)
            return
        }
        print("file exists")
        XCTAssertNotNil(dict["prod"]?["client_id"])
        XCTAssertNotNil(dict["preprod"]?["client_id"])
        XCTAssertNotNil(dict["prod"]?["client_secret"])
        XCTAssertNotNil(dict["preprod"]?["redirect_uri"])
        XCTAssertNotNil(dict["prod"]?["client_secret"])
        XCTAssertNotNil(dict["preprod"]?["redirect_uri"])


    }

}
