//
//  CacheManagerTests.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 16/02/2021.
//

import XCTest
import CoreLocation
@testable import herow_sdk_ios
class CacheManagerTests: XCTestCase, CacheListener {

    let cacheManager = CacheManager(db: CoreDataManager<HerowZone, HerowAccess, HerowPoi, HerowCampaign, HerowNotification, HerowCapping, HerowQuadTreeNode, HerowQuadTreeLocation>())
    override func setUpWithError() throws {

        cacheManager.registerCacheListener(listener: self)
        cacheManager.cleanCache()


        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    func willCacheUpdate() {
        print("cache will update")
    }
    
    func onCacheUpdate(forGeoHash: String?) {
        print("cache update")
    }
    override func tearDownWithError() throws {

        cacheManager.unregisterCacheListener(listener: self)
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    func testListeners() throws {
        cacheManager.registerCacheListener(listener: self)
        XCTAssertTrue(cacheManager.listeners.count == 1)
    }

    func testListeners2() throws {
        cacheManager.unregisterCacheListener(listener: self)
        XCTAssertTrue(cacheManager.listeners.count == 0)
    }
    func testZone() throws {
        let campaigns = ["1","2","3","4"]
        let testFailExpectation = expectation(description: "testFailExpectation")
        let access = APIAccess(id: "access1", name: "access1Name", address: "accessAdress1")
        let zone = APIZone(hash: "hash", lat: 49.371864318847656, lng: 3.8972530364990234, radius: 30, campaigns: campaigns, access: access)
        let zone2 = APIZone(hash: "hash2", lat: 49.371864318847656, lng: 3.8972530364990234, radius: 30, campaigns: campaigns, access: access)
        cacheManager.saveZones(items: [zone, zone2]) { [self] in
            XCTAssertTrue(self.cacheManager.getZones().count == 2)
            XCTAssertTrue(self.cacheManager.getZones(ids: ["hash"]).count == 1)
            XCTAssertTrue(self.cacheManager.getZones(ids: ["hash2"]).count == 1)
            XCTAssertTrue(self.cacheManager.getZones(ids: ["hash2","hash"]).count == 2)
            self.cacheManager.cleanCache ()
            XCTAssertTrue(self.cacheManager.getZones().count == 0)
            testFailExpectation.fulfill()
        }

        waitForExpectations(timeout:30) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func testPOI() throws {
        let testFailExpectation = expectation(description: "testFailExpectation")
        let poi = APIPoi(id:"id", tags:  ["1","2","3"], lat: 49.371864318847656, lng: 3.8972530364990234)
        cacheManager.savePois(items: [poi]) { [self] in
            XCTAssertTrue(self.cacheManager.getPois().count == 1)
            let location = CLLocation(latitude:  49.371864318847656, longitude:  3.8972530364990234)
            XCTAssertTrue(self.cacheManager.getNearbyPois(location).count == 1)
            self.cacheManager.cleanCache()
            XCTAssertTrue(self.cacheManager.getPois().count == 0)
            testFailExpectation.fulfill()
        }
        waitForExpectations(timeout:30) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func testCapping() throws {
        let testFailExpectation = expectation(description: "testFailExpectation")
        let capping = HerowCapping(id: "id", razDate: Date(), count: 0)
        cacheManager.saveCapping(capping) {
            if  let savedCapping =   self.cacheManager.getCapping(id: "id") {
                XCTAssertTrue(savedCapping.getId() == "id")
                XCTAssertTrue(savedCapping.getCount() == 0)

                savedCapping.setCount(count: 2)
                self.cacheManager.saveCapping(savedCapping) {
                    let savedCapping =   self.cacheManager.getCapping(id: "id")
                    XCTAssertTrue(savedCapping?.getId() == "id")
                    XCTAssertTrue(savedCapping?.getCount() == 2)

                    testFailExpectation.fulfill()
                }
            }

        }
        waitForExpectations(timeout:30) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }


    func testCampaign() throws {
        let testFailExpectation = expectation(description: "testFailExpectation")

        let campaign: APICampaign = APICampaign(id: "ggggg",
                                                name: "name",
                                                begin: 0,
                                                end: nil,
                                                cappings: nil,
                                                daysRecurrence: [""],
                                                notification: nil,
                                                startHour: "",
                                                stopHour: "")


        self.cacheManager.saveCampaigns(items: [campaign]) { [self] in
            XCTAssertTrue(self.cacheManager.getCampaigns().count == 1)
            XCTAssertTrue(self.cacheManager.getCampaigns().count == 1)
            self.cacheManager.cleanCache()
            XCTAssertTrue(self.cacheManager.getPois().count == 0)
            testFailExpectation.fulfill()
        }




        waitForExpectations(timeout:30) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func testBuilder() throws {
        let coordinates = CLLocationCoordinate2D(latitude: 49.371864318847656, longitude: 3.8972530364990234)
        let tupple =  Builder.create(zoneNumber: 10, campaignNumberPerZone: 5, from: coordinates)
        let zones = tupple.0
        let campaigns = tupple.1
        XCTAssertTrue(zones.count == 10)
        XCTAssertTrue(campaigns.count == 50)
    }

    func testArround() throws {
        let testFailExpectation = expectation(description: "testFailExpectation")
        let coordinates = CLLocationCoordinate2D(latitude: 49.371864318847656, longitude: 3.8972530364990234)
        let tupple =  Builder.create(zoneNumber: 10, campaignNumberPerZone: 5, from: coordinates)
        let zones = tupple.0
        let campaigns = tupple.1
        cacheManager.save(zones: zones, campaigns: campaigns, pois: nil) {
            XCTAssertTrue(self.cacheManager.getZones().count == 10)
            XCTAssertTrue(self.cacheManager.getCampaigns().count == 50)
            for zone in zones {
                let hash = zone.hash
                XCTAssertTrue(self.cacheManager.getZones(ids: [hash]).count == 1)
                XCTAssertTrue(self.cacheManager.getCampaignsForZone(zone).count  == 5)

            }
            testFailExpectation.fulfill()
        }
        waitForExpectations(timeout:30) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func testArround2() throws {
        let testFailExpectation = expectation(description: "testFailExpectation")
        let coordinates = CLLocationCoordinate2D(latitude: 49.371864318847656, longitude: 3.8972530364990234)
        let tupple =  Builder.create(zoneNumber: 10, campaignNumberPerZone: 5, from: coordinates, distance: 10000)
        let zones = tupple.0
        let campaigns = tupple.1

        cacheManager.save(zones: zones, campaigns: campaigns, pois: nil) {
            XCTAssertTrue(self.cacheManager.getZones().count == 10)
            XCTAssertTrue(self.cacheManager.getCampaigns().count == 50)
            XCTAssertTrue(self.cacheManager.getNearbyZones(CLLocation(latitude: 49.371864318847656, longitude: 3.8972530364990234)).count == 2)
            testFailExpectation.fulfill()
        }
        waitForExpectations(timeout:30) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }

    }

    func testArround3() throws {
        let testFailExpectation = expectation(description: "testFailExpectation")
        let coordinates = CLLocationCoordinate2D(latitude: 49.371864318847656, longitude: 3.8972530364990234)
        let tupple =  Builder.create(zoneNumber: 10, campaignNumberPerZone: 5, from: coordinates, distance: 5000)
        let zones = tupple.0
        let campaigns = tupple.1

        cacheManager.save(zones: zones, campaigns: campaigns, pois: nil) {
            XCTAssertTrue(self.cacheManager.getZones().count == 10)
            XCTAssertTrue(self.cacheManager.getCampaigns().count == 50)
            XCTAssertTrue(self.cacheManager.getNearbyZones(CLLocation(latitude: 49.371864318847656, longitude: 3.8972530364990234)).count == 4)
            testFailExpectation.fulfill()
        }
        waitForExpectations(timeout:30) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }

    }

    func testArround4() throws {
        let testFailExpectation = expectation(description: "testFailExpectation")
        let coordinates = CLLocationCoordinate2D(latitude: 49.371864318847656, longitude: 3.8972530364990234)
        let pois =  Builder.createPois(number: 10, from: coordinates,distance: 5000)
        let location = CLLocation(latitude: 49.371864318847656, longitude: 3.8972530364990234)
        cacheManager.savePois(items: pois) {
            XCTAssertTrue(self.cacheManager.getPois().count == 10)
            XCTAssertTrue(self.cacheManager.getNearbyPois(location, distance: 20000, count: 10).count == 4)
            XCTAssertTrue(self.cacheManager.getNearbyPois(location, distance: 20000, count: 2).count == 2)
            XCTAssertTrue(self.cacheManager.getNearbyPois(location, distance: 5000, count: 10).count == 1)
            XCTAssertTrue(self.cacheManager.getNearbyPois(location, distance: 10000, count: 10).count == 2)
            XCTAssertTrue(self.cacheManager.getNearbyPois(location, distance: 10000, count: 1).count == 1)
            testFailExpectation.fulfill()
        }
        waitForExpectations(timeout:30) { error in
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
