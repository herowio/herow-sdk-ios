//
//  EventDispatcherTests.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 01/03/2021.
//

import XCTest
import CoreLocation
@testable import herow_sdk_ios
class TestEventListener: EventListener {
    var event: Event?
    var infos: [ZoneInfo]?
    func didReceivedEvent(_ event: Event, infos: [ZoneInfo]) {
        self.event = event
        self.infos = infos
    }
}

class EventDispatcherTests: XCTestCase {
    let eventDispatcher = EventDispatcher()
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRegister() throws {
        eventDispatcher.registerListener(TestEventListener())
        eventDispatcher.registerListener(TestEventListener())
        eventDispatcher.registerListener(TestEventListener())
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_ENTER]?.count == 3)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_EXIT]?.count == 3)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_VISIT]?.count == 3)
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testUnRegister() throws {
        let listener1 = TestEventListener()
        let listener2 = TestEventListener()
        let listener3 = TestEventListener()

        eventDispatcher.registerListener(listener1)
        eventDispatcher.registerListener(listener2)
        eventDispatcher.registerListener(listener3)

        eventDispatcher.stopListening(forEvent: .GEOFENCE_ENTER, listener: listener1)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_ENTER]?.count == 2)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_EXIT]?.count == 3)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_VISIT]?.count == 3)

        eventDispatcher.stopListening(forEvent: .GEOFENCE_EXIT, listener: listener1)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_ENTER]?.count == 2)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_EXIT]?.count == 2)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_VISIT]?.count == 3)

        eventDispatcher.stopListening(forEvent: .GEOFENCE_VISIT, listener: listener1)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_ENTER]?.count == 2)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_EXIT]?.count == 2)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_VISIT]?.count == 2)

        eventDispatcher.stopListening(forEvent: .GEOFENCE_ENTER, listener: listener2)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_ENTER]?.count == 1)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_EXIT]?.count == 2)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_VISIT]?.count == 2)

        eventDispatcher.stopListening(forEvent: .GEOFENCE_EXIT, listener: listener2)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_ENTER]?.count == 1)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_EXIT]?.count == 1)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_VISIT]?.count == 2)

        eventDispatcher.stopListening(forEvent: .GEOFENCE_VISIT, listener: listener2)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_ENTER]?.count == 1)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_EXIT]?.count == 1)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_VISIT]?.count == 1)

        eventDispatcher.stopListening(forEvent: .GEOFENCE_ENTER, listener: listener3)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_ENTER]?.count == 0)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_EXIT]?.count == 1)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_VISIT]?.count == 1)

        eventDispatcher.stopListening(forEvent: .GEOFENCE_EXIT, listener: listener3)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_ENTER]?.count == 0)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_EXIT]?.count == 0)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_VISIT]?.count == 1)

        eventDispatcher.stopListening(forEvent: .GEOFENCE_VISIT, listener: listener3)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_ENTER]?.count == 0)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_EXIT]?.count == 0)
        XCTAssertTrue(eventDispatcher.listeners[.GEOFENCE_VISIT]?.count == 0)

    }

    func testPost() throws {
        let listener1 = TestEventListener()
        eventDispatcher.registerListener(listener1)
        eventDispatcher.post(event: .GEOFENCE_ENTER, infos: [ZoneInfo(hash: "hash")])
        XCTAssertTrue(listener1.event == .GEOFENCE_ENTER)
        XCTAssertTrue(listener1.infos?.first?.zoneHash == "hash")
        eventDispatcher.post(event: .GEOFENCE_EXIT, infos: [ZoneInfo(hash: "hash")])
        XCTAssertTrue(listener1.event == .GEOFENCE_EXIT)
        XCTAssertTrue(listener1.infos?.first?.zoneHash == "hash")
        eventDispatcher.post(event: .GEOFENCE_VISIT, infos: [ZoneInfo(hash: "hash")])
        XCTAssertTrue(listener1.event == .GEOFENCE_VISIT)
        XCTAssertTrue(listener1.infos?.first?.zoneHash == "hash")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
