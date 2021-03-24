//
//  DetectionengineTests.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 02/03/2021.
//

import XCTest
import CoreLocation
@testable import herow_sdk_ios

class TestDetectionListener: DetectionEngineListener {


    var location : CLLocation?
    func onLocationUpdate(_ location: CLLocation, from: UpdateType) {
        self.location = location
    }
}

class TestMonitotingListener: ClickAndConnectListener {
    var listeningState: Bool = false
    func didStopClickAndConnect() {
        listeningState = false
    }

    func didStartClickAndConnect() {
        listeningState = true
    }
}

class DetectionengineTests: XCTestCase {
    let timeProvider =  TimeProviderForTests()
    var detectionEngine : DetectionEngine?
    override func setUpWithError() throws {
        timeProvider.updateNow()
       detectionEngine = DetectionEngine(MockLocationManager(),timeProvider: timeProvider)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {

        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testListeners() throws {
        let detetionListener1 = TestDetectionListener()
        let detetionListener2 = TestDetectionListener()
        let detetionListener3 = TestDetectionListener()
        guard let detectionEngine = self.detectionEngine else {
            return
        }
        XCTAssertTrue(detectionEngine.detectionListners.count == 0)
        detectionEngine.registerDetectionListener(listener: detetionListener1)
        XCTAssertTrue(detectionEngine.detectionListners.count == 1)
        detectionEngine.registerDetectionListener(listener: detetionListener2)
        XCTAssertTrue(detectionEngine.detectionListners.count == 2)
        detectionEngine.registerDetectionListener(listener: detetionListener3)
        XCTAssertTrue(detectionEngine.detectionListners.count == 3)
        detectionEngine.unregisterDetectionListener(listener: detetionListener1)
        XCTAssertTrue(detectionEngine.detectionListners.count == 2)
        detectionEngine.unregisterDetectionListener(listener: detetionListener2)
        XCTAssertTrue(detectionEngine.detectionListners.count == 1)
        detectionEngine.unregisterDetectionListener(listener: detetionListener3)
        XCTAssertTrue(detectionEngine.detectionListners.count == 0)


        let monitoringListenner1 = TestMonitotingListener()
        let monitoringListenner2 = TestMonitotingListener()
        let monitoringListenner3 = TestMonitotingListener()
        XCTAssertTrue(detectionEngine.monitoringListeners.count == 0)
        detectionEngine.registerClickAndCollectListener(listener: monitoringListenner1)
        XCTAssertTrue(detectionEngine.monitoringListeners.count == 1)
        detectionEngine.registerClickAndCollectListener(listener: monitoringListenner2)
        XCTAssertTrue(detectionEngine.monitoringListeners.count == 2)
        detectionEngine.registerClickAndCollectListener(listener: monitoringListenner3)
        XCTAssertTrue(detectionEngine.monitoringListeners.count == 3)
        detectionEngine.unregisterClickAndCollectListener(listener: monitoringListenner1)
        XCTAssertTrue(detectionEngine.monitoringListeners.count == 2)
        detectionEngine.unregisterClickAndCollectListener(listener: monitoringListenner2)
        XCTAssertTrue(detectionEngine.monitoringListeners.count == 1)
        detectionEngine.unregisterClickAndCollectListener(listener: monitoringListenner3)
        XCTAssertTrue(detectionEngine.monitoringListeners.count == 0)
    }

    func testDispatch() throws {
        guard let detectionEngine = self.detectionEngine else {
            return
        }
        let location1 = CLLocation(latitude: 10, longitude: 10)
        let location2 = Builder.locationWithBearing(bearingRadians: 0, distanceMeters: 10, origin: location1)
        let location3 = Builder.locationWithBearing(bearingRadians: 0, distanceMeters: 40, origin: location2)
        XCTAssertTrue(detectionEngine.dispatchLocation(location1))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertFalse(detectionEngine.dispatchLocation(location2))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertTrue(detectionEngine.dispatchLocation(location3))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertFalse(detectionEngine.dispatchLocation(location3))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertTrue(detectionEngine.dispatchLocation(location2))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertTrue(detectionEngine.dispatchLocation(location3))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertFalse(detectionEngine.dispatchLocation(location3))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertFalse(detectionEngine.dispatchLocation(location3))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertFalse(detectionEngine.dispatchLocation(location3))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertFalse(detectionEngine.dispatchLocation(location3))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertFalse(detectionEngine.dispatchLocation(location3))
        
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertTrue(detectionEngine.dispatchLocation(location3))
        // stop skipping because 5
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertTrue(detectionEngine.dispatchLocation(location1))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertFalse(detectionEngine.dispatchLocation(location1))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertFalse(detectionEngine.dispatchLocation(location1))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertFalse(detectionEngine.dispatchLocation(location1))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertFalse(detectionEngine.dispatchLocation(location1))
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertFalse(detectionEngine.dispatchLocation(location1))
        // stop skipping because 5
        timeProvider.addingTimeInterval(timeInterval: 10)
        XCTAssertTrue(detectionEngine.dispatchLocation(location1))
    }

    func testReceiveConfig() throws {
        guard let detectionEngine = self.detectionEngine else {
            return
        }
        var config = APIConfig(cacheInterval: 1000, configInterval: 1000, enabled: true)
        detectionEngine.didRecievedConfig(config)
        XCTAssertTrue(detectionEngine.isUpdatingPosition)
         config = APIConfig(cacheInterval: 1000, configInterval: 1000, enabled: false)
        detectionEngine.didRecievedConfig(config)
        detectionEngine.didRecievedConfig(config)
        XCTAssertFalse(detectionEngine.isUpdatingPosition)
    }

    func testVisitMonitoring() throws {
        guard let detectionEngine = self.detectionEngine else {
            return
        }
        detectionEngine.startMonitoringVisits()
        XCTAssertTrue(detectionEngine.isMonitoringVisit)
        detectionEngine.stopMonitoringVisits()
        XCTAssertFalse(detectionEngine.isMonitoringVisit)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
