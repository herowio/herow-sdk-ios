//
//  ZoneProviderTests.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 18/02/2021.
//

import XCTest
import CoreLocation
@testable import herow_sdk_ios
class ZoneProviderTests: XCTestCase {

    var zoneProvider: ZoneProvider?
    var coordinatesEntry = CLLocationCoordinate2D(latitude: 49.371864318847656, longitude: 3.8972530364990234)
    var coordinatesExit = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    let cacheManager = CacheManager(db: CoreDataManager<HerowZone, HerowAccess, HerowPoi, HerowCampaign, HerowNotification, HerowCapping>())

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws {

    }

    func testEntry() throws {
        let testExpectation = expectation(description: "testEntryExpectation")
        cacheManager.cleanCache()
        coordinatesEntry = CLLocationCoordinate2D(latitude: 49.371864318847656, longitude: 3.8972530364990234)
        let tupple =  Builder.create(zoneNumber: 10, campaignNumberPerZone: 5, from: coordinatesEntry, distance: 75)
        let zones = tupple.0
        let campaigns = tupple.1
        cacheManager.save(zones: zones, campaigns: campaigns, pois: [], completion: {
            self.zoneProvider = ZoneProvider(cacheManager: self.cacheManager, eventDisPatcher: EventDispatcher())
            let selection =  self.zoneProvider?.zoneDetectionProcess(CLLocation(latitude: self.coordinatesEntry.latitude, longitude: self.coordinatesEntry.longitude))
            XCTAssertTrue(selection?.zones.count == 1)
            testExpectation.fulfill()
        })
        waitForExpectations(timeout: 30) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func testExit() throws {
        let testExpectation = expectation(description: "testExitExpectation")
        cacheManager.cleanCache()
        coordinatesEntry = CLLocationCoordinate2D(latitude: 49.371864318847656, longitude: 3.8972530364990234)
        let tupple =  Builder.create(zoneNumber: 10, campaignNumberPerZone: 5, from: coordinatesEntry, distance: 75)
        let zones = tupple.0
        let campaigns = tupple.1
        cacheManager.save(zones: zones, campaigns: campaigns, pois: [], completion: {
            self.zoneProvider = ZoneProvider(cacheManager: self.cacheManager, eventDisPatcher: EventDispatcher())
            let selection =  self.zoneProvider?.zoneDetectionProcess(CLLocation(latitude: self.coordinatesExit.latitude, longitude: self.coordinatesExit.longitude))
            XCTAssertTrue(selection?.zones.count == 0)
            testExpectation.fulfill()
        })

        waitForExpectations(timeout: 30) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
