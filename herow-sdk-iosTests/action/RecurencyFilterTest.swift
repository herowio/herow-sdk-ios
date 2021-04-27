//
//  RecurencyFilterTest.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 26/04/2021.
//

import XCTest
@testable import herow_sdk_ios
class RecurencyFilterTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testValidation() throws {
        let camp = HerowCampaign(id: "gh", company: "hj", name: "jh", createdDate: 1234, modifiedDate: 12345, deleted: false, simpleId: "gg", begin: 1234, end: 1234, realTimeContent: false, intervals: nil, cappings: nil, triggers: [String:Int](), daysRecurrence: ["Monday", "Wednesday", "Friday","Sunday"], recurrenceEnabled: false, tz: "ee", notification: nil, startHour: "09:00", stopHour: "19:15")

        let timeProvider = TimeProviderForTests()
        let filter =   RecurencyFilter(timeProvider: timeProvider)
        timeProvider.date  = Date().next(.monday)
        XCTAssertTrue( filter.createNotification(campaign: camp))
        timeProvider.date  = Date().next(.wednesday)
        XCTAssertTrue( filter.createNotification(campaign: camp))
        timeProvider.date  = Date().next(.friday)
        XCTAssertTrue( filter.createNotification(campaign: camp))
        timeProvider.date  = Date().next(.sunday)
        XCTAssertTrue( filter.createNotification(campaign: camp))
        timeProvider.date  = Date().next(.tuesday)
        XCTAssertFalse( filter.createNotification(campaign: camp))
        timeProvider.date  = Date().next(.thursday)
        XCTAssertFalse( filter.createNotification(campaign: camp))
        timeProvider.date  = Date().next(.saturday)
        XCTAssertFalse( filter.createNotification(campaign: camp))

        let camp2 = HerowCampaign(id: "gh", company: "hj", name: "jh", createdDate: 1234, modifiedDate: 12345, deleted: false, simpleId: "gg", begin: 1234, end: 1234, realTimeContent: false, intervals: nil, cappings: nil, triggers: [String:Int](), daysRecurrence: [String](), recurrenceEnabled: false, tz: "ee", notification: nil, startHour: "09:00", stopHour: "19:15")

        timeProvider.date  = Date().next(.monday)
        XCTAssertTrue( filter.createNotification(campaign: camp2))
        timeProvider.date  = Date().next(.wednesday)
        XCTAssertTrue( filter.createNotification(campaign: camp2))
        timeProvider.date  = Date().next(.friday)
        XCTAssertTrue( filter.createNotification(campaign: camp2))
        timeProvider.date  = Date().next(.sunday)
        XCTAssertTrue( filter.createNotification(campaign: camp2))
        timeProvider.date  = Date().next(.tuesday)
        XCTAssertTrue( filter.createNotification(campaign: camp2))
        timeProvider.date  = Date().next(.thursday)
        XCTAssertTrue( filter.createNotification(campaign: camp2))
        timeProvider.date  = Date().next(.saturday)
        XCTAssertTrue( filter.createNotification(campaign: camp2))
     
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
