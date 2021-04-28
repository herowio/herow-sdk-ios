//
//  CappingFilterTest.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 28/04/2021.
//

import XCTest
@testable import herow_sdk_ios
class CappingFilterTest: XCTestCase {
    let cacheManager = CacheManager(db: CoreDataManager<HerowZone, HerowAccess, HerowPoi, HerowCampaign, HerowInterval, HerowNotification, HerowCapping>())
    override func setUpWithError() throws {
        cacheManager.cleanCapping(nil)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testValidation() throws {
      //  let testFailExpectation = expectation(description: "testFailExpectation")
        let camp = HerowCampaign(id: "gh", company: "hj", name: "jh", createdDate: 1234, modifiedDate: 12345, deleted: false, simpleId: "gg", begin: 0, end: nil, realTimeContent: false, intervals: nil, cappings: [maxNumberNotifications : 3, minTimeBetweenTwoNotifications : oneDayMilliSeconds], triggers: [String:Int](), daysRecurrence: [String](), recurrenceEnabled: false, tz: "ee", notification: nil, startHour: "09:00", stopHour: "19:15")

        let timeProvider = TimeProviderForTests()
        let filter = CappingFilter(timeProvider: timeProvider, cacheManager: cacheManager)

        XCTAssertTrue(filter.createNotification(campaign: camp) )
        XCTAssertTrue(filter.createNotification(campaign: camp) )
        XCTAssertTrue(filter.createNotification(campaign: camp) )
        XCTAssertFalse(filter.createNotification(campaign: camp) )

        timeProvider.date =   timeProvider.date.tomorrow()
        XCTAssertFalse(filter.createNotification(campaign: camp) )

        timeProvider.setHour(hour: 10, minutes: 0)

        XCTAssertTrue(filter.createNotification(campaign: camp) )
        XCTAssertTrue(filter.createNotification(campaign: camp) )
        XCTAssertTrue(filter.createNotification(campaign: camp) )
        XCTAssertFalse(filter.createNotification(campaign: camp) )

    }

    func testValidation2() throws {
      //  let testFailExpectation = expectation(description: "testFailExpectation")
        let camp = HerowCampaign(id: "gh", company: "hj", name: "jh", createdDate: 1234, modifiedDate: 12345, deleted: false, simpleId: "gg", begin: 0, end: nil, realTimeContent: false, intervals: nil, cappings: [maxNumberNotifications : 3, minTimeBetweenTwoNotifications : 3 * oneDayMilliSeconds], triggers: [String:Int](), daysRecurrence: [String](), recurrenceEnabled: false, tz: "ee", notification: nil, startHour: nil, stopHour: nil)

        let timeProvider = TimeProviderForTests()
        let filter = CappingFilter(timeProvider: timeProvider, cacheManager: cacheManager)

        XCTAssertTrue(filter.createNotification(campaign: camp) )
        XCTAssertTrue(filter.createNotification(campaign: camp) )
        XCTAssertTrue(filter.createNotification(campaign: camp) )
        XCTAssertFalse(filter.createNotification(campaign: camp) )

        timeProvider.date =   timeProvider.date.tomorrow().tomorrow().tomorrow()
        XCTAssertTrue(filter.createNotification(campaign: camp) )

        timeProvider.setHour(hour: 0, minutes: 1)

        XCTAssertTrue(filter.createNotification(campaign: camp) )
        XCTAssertTrue(filter.createNotification(campaign: camp) )
        XCTAssertFalse(filter.createNotification(campaign: camp) )

    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
