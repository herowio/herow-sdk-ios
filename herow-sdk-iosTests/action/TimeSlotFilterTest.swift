//
//  TimeSlotFilterTest.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 26/04/2021.
//

import XCTest
@testable import herow_sdk_ios
class TimeSlotFilterTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testValidation() throws {
        let camp = HerowCampaign(id: "gh", company: "hj", name: "jh", createdDate: 1234, modifiedDate: 12345, deleted: false, simpleId: "gg", begin: 1234, end: 1234, realTimeContent: false, intervals: nil, cappings: nil, triggers: [String:Int](), daysRecurrence: [String](), recurrenceEnabled: false, tz: "ee", notification: nil, startHour: "09:00", stopHour: "19:15")

        let timeProvider = TimeProviderForTests()
        let filter =   TimeSlotFilter(timeProvider: timeProvider)
        timeProvider.setHour(hour: 7, minutes: 0)
        XCTAssertFalse( filter.createNotification(campaign: camp))
        timeProvider.setHour(hour: 10, minutes: 0)
        XCTAssertTrue( filter.createNotification(campaign: camp))
        timeProvider.setHour(hour: 19, minutes: 0)
        XCTAssertFalse( filter.createNotification(campaign: camp))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
