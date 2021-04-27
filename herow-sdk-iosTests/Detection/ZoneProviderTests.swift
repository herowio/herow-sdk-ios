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

    override func setUpWithError() throws {

       let cacheManager = CacheManager(db: CoreDataManager<HerowZone, HerowAccess, HerowPoi, HerowCampaign, HerowInterval, HerowNotification, HerowCapping>())
        cacheManager.cleanCache()
        coordinatesEntry = CLLocationCoordinate2D(latitude: 49.371864318847656, longitude: 3.8972530364990234)
        let tupple =  Builder.create(zoneNumber: 10, campaignNumberPerZone: 5, from: coordinatesEntry, distance: 75)
        let zones = tupple.0
        let campaigns = tupple.1
        cacheManager.save(zones: zones, campaigns: campaigns, pois: [], completion: nil)
        zoneProvider = ZoneProvider(cacheManager: cacheManager, eventDisPatcher: EventDispatcher())
    }

    override func tearDownWithError() throws {

    }

    func testEntry() throws {
        let selection =  zoneProvider?.zoneDetectionProcess(CLLocation(latitude: coordinatesEntry.latitude, longitude: coordinatesEntry.longitude))
        XCTAssertTrue(selection?.zones.count == 1)
    }

    func testExit() throws {
        let selection =  zoneProvider?.zoneDetectionProcess(CLLocation(latitude: coordinatesExit.latitude, longitude: coordinatesExit.longitude))
        XCTAssertTrue(selection?.zones.count == 0)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
