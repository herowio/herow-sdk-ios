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

    override func setUpWithError() throws {
       let cacheManager = CacheManager(db: CoreDataManager<HerowZone, HerowAccess, HerowPoi, HerowCampaign, HerowInterval, HerowNotification>())
        let coordinates = CLLocationCoordinate2D(latitude: 49.371864318847656, longitude: 3.8972530364990234)
        let tupple =  Builder.create(zoneNumber: 10, campaignNumberPerZone: 5, from: coordinates, distance: 10000)
        let zones = tupple.0
        let campaigns = tupple.1
        cacheManager.saveZones(items: zones, completion: nil)
        cacheManager.saveCampaigns(items: campaigns, completion: nil)
       let zoneProvider = ZoneProvider(cacheManager: cacheManager, eventDisPatcher: EventDispatcher())
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

}
