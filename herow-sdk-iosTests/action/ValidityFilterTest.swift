//
//  ValidityFilterTest.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 28/04/2021.
//

import XCTest
@testable import herow_sdk_ios
class ValidityFilterTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testValidation() throws {
       guard let start = Date().setTime(hour: 0, min: 0)?.timeIntervalSince1970,
        let end = Date().setTime(hour:12, min: 0)?.timeIntervalSince1970
       else {
        return
       }

        let camp = HerowCampaign(id: "gh", name: "jh", begin: start * 1000, end: end * 1000 , cappings: nil, daysRecurrence: [String](), notification: nil, startHour: "09:00", stopHour: "19:15")
        let timeProvider = TimeProviderForTests()
        let filter = ValidityFilter(timeProvider: timeProvider)
        timeProvider.setHour(hour: 8, minutes: 0)
        XCTAssertTrue(filter.createNotification(campaign: camp))
        timeProvider.setHour(hour: 11, minutes: 0)
        XCTAssertTrue(filter.createNotification(campaign: camp))
        timeProvider.setHour(hour: 11, minutes: 59)
        XCTAssertTrue(filter.createNotification(campaign: camp))
        timeProvider.setHour(hour: 12, minutes: 1)
        XCTAssertFalse(filter.createNotification(campaign: camp))
        timeProvider.setHour(hour: 16, minutes: 0)
        XCTAssertFalse(filter.createNotification(campaign: camp))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
