//
//  GeofenceManagerTests.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 17/03/2021.
//

import XCTest
import CoreLocation
@testable import herow_sdk_ios
class GeofenceManagerTests: XCTestCase {
    var locationManager: LocationManager = MockLocationManager()
    var herowInitializer : HerowInitializer?

    override func setUpWithError() throws {
        herowInitializer = HerowInitializer(locationManager: locationManager)
        herowInitializer?.reset()
        _ = herowInitializer?.configPlatform(.preprod)
            .configApp(identifier: "appdemo98", sdkKey: "4WQmEg3I6tAsFQG9ZN8T")
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMonitoring() throws {
        guard let  geofenceManager = herowInitializer?.geofenceManager else {
            XCTAssert(true)
            return
        }
        let location1 = CLLocation(latitude: 10, longitude: 10).coordinate
        let tupple =  Builder.create(zoneNumber: 1, campaignNumberPerZone: 5, from: location1)
        let zones = tupple.0
        geofenceManager.createPlaceRegions(places: zones)
        XCTAssertTrue(geofenceManager.getMonitoredRegions().count == 1)
       _ = geofenceManager.cleanPlaceMonitoredRegions(places: zones)
        XCTAssertTrue(geofenceManager.getMonitoredRegions().count == 1)
        geofenceManager.createNewMovingGeofences( location: CLLocation(latitude: 10, longitude: 10))
        XCTAssertTrue(geofenceManager.getMonitoredRegions().count == 5)
    _ = geofenceManager.cleanPlaceMonitoredRegions(places: zones)
        XCTAssertTrue(geofenceManager.getMonitoredRegions().count == 1)
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
