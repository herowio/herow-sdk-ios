//
//  HerowInitializerTests.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 16/02/2021.
//

import XCTest
import CoreLocation
@testable import herow_sdk_ios
class HerowInitializerTests: XCTestCase {
    var locationManager: LocationManager = MockLocationManager()
    var herowInitializer : HerowInitializer?
    override func setUpWithError() throws {
        setup()
    }

    func setup() {
        herowInitializer = HerowInitializer(locationManager: locationManager)
        herowInitializer?.reset()
        _ = herowInitializer?.configPlatform(.preprod)
            .configApp(identifier: "appdemo98", sdkKey: "4WQmEg3I6tAsFQG9ZN8T")
    }



    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testClickAnCollect() throws {
        let testFailExpectation = expectation(description: "testFailExpectation")
        herowInitializer?.synchronize {
            guard let herowInitializer =  self.herowInitializer else {
                return }
            herowInitializer.launchClickAndCollect()
            XCTAssertTrue(herowInitializer.isOnClickAndCollect())

            herowInitializer.stopClickAndCollect()
            XCTAssertFalse(herowInitializer.isOnClickAndCollect())

            testFailExpectation.fulfill()
        }

        waitForExpectations(timeout:30) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func testOptin() throws {
        guard let herowInitializer =  self.herowInitializer else {
            return }
        herowInitializer.acceptOptin()
        XCTAssertTrue(herowInitializer.getOptinValue())

        herowInitializer.refuseOptin()
        XCTAssertFalse(herowInitializer.getOptinValue())
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
