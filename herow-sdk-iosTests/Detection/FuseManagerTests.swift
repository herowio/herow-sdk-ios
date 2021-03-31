//
//  FuseManagerTests.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 15/03/2021.
//

import XCTest
import CoreLocation
@testable import herow_sdk_ios
class FuseManagerTests: XCTestCase {

    let timeProvider = TimeProviderForTests()
    var fuseManager : FuseManager?
    override func setUpWithError() throws {
        fuseManager = FuseManager(dataHolder:  DataHolderUserDefaults(suiteName: "tests"), timeProvider: timeProvider)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test() throws {
        guard let fuseManager = fuseManager else {
            XCTAssert(true)
            return
        }
        for  _ in 0...FuseManager.countLimit - 1 {
        fuseManager.onLocationUpdate(CLLocation())
            XCTAssertFalse(fuseManager.isActivated())
        }
        fuseManager.onLocationUpdate(CLLocation())
        XCTAssertTrue(fuseManager.isActivated())

        timeProvider.addingTimeInterval(timeInterval:  FuseManager.timeWindow )
        fuseManager.onLocationUpdate(CLLocation())
        XCTAssertFalse(fuseManager.isActivated())
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testRegister() throws {
        guard let fuseManager = fuseManager else {
            XCTAssert(true)
            return
        }
        let listener = Listener()
        fuseManager.registerFuseManagerListener(listener: listener)
        XCTAssertTrue(fuseManager.listeners.count == 1)
        fuseManager.unregisterFuseManagerListener(listener: listener)
        XCTAssertTrue(fuseManager.listeners.count == 0)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

class Listener: FuseManagerListener {
    func onFuseUpdate(_ activated: Bool, location: CLLocation?) {

    }
}
