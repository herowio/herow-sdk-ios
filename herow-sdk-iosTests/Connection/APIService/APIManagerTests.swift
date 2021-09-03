//
//  APIManagerTests.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 12/02/2021.
//

import XCTest
@testable import herow_sdk_ios

class APIManagerTests: XCTestCase, ConfigListener  {
    func didRecievedConfig(_ config: APIConfig) {
        
    }

    let connectionInfos = ConnectionInfo(platform: .test)
    var apiManager: APIManager?

    override func setUpWithError() throws {
        apiManager = APIManager(connectInfo: connectionInfos, herowDataStorage: HerowDataStorage(dataHolder:DataHolderUserDefaults(suiteName: "Test")), cacheManager: CacheManager(db: CoreDataManager<HerowZone, HerowAccess, HerowPoi, HerowCampaign, HerowNotification, HerowCapping,HerowQuadTreeNode, HerowQuadTreeLocation, HerowPeriod>()))
        apiManager?.configure(connectInfo: connectionInfos)
        apiManager?.registerConfigListener(listener: self)
        self.apiManager?.user = User(login: "toto", password: "toto")
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSequenceGetConfig() throws {
        let testExpectation = expectation(description: "testExpectation")
        apiManager?.currentUserInfo = UserInfo(adId: "idfaidfaidfaidfaidfaidfaidfa",
                                               adStatus: true,
                                               herowId: "herowId",
                                               customId: "customId", lang: "lang",
                                               offset: 3600,
                                               optins:[Optin.optinDataOk])



        apiManager?.getConfig(completion: { config, error in
            if let _ = error  {
                    XCTAssertTrue(false)
            } else {
                XCTAssertTrue(true)
            }
            testExpectation.fulfill()
        })
        waitForExpectations(timeout: 30) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }

        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testCacheSequenceWithOptin() throws {
        apiManager?.herowDataStorage.setOptin(optin: Optin.optinDataOk)
        let testExpectation = expectation(description: "testExpectation")
        apiManager?.currentUserInfo = UserInfo(adId: "idfaidfaidfaidfaidfaidfaidfa",
                                               adStatus: true,
                                               herowId: "herowId",
                                               customId: "customId", lang: "lang",
                                               offset: 3600,
                                               optins:[Optin.optinDataOk])



        apiManager?.getCache(geoHash: "u0fb", completion: { (cache, error) in
            if let _ = error  {
                    XCTAssertTrue(false)
            } else {
                XCTAssertTrue(true)
            }
            testExpectation.fulfill()
        })
        waitForExpectations(timeout: 60) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

        func testCacheSequenceWithoutOptin() throws {
            apiManager?.herowDataStorage.setOptin(optin: Optin.optinDataNotOk)
            let testExpectation = expectation(description: "testExpectation")
            apiManager?.currentUserInfo = UserInfo(adId: "idfaidfaidfaidfaidfaidfaidfa",
                                                   adStatus: true,
                                                   herowId: "herowId",
                                                   customId: "customId", lang: "lang",
                                                   offset: 3600,
                                                   optins:[Optin.optinDataOk])



            apiManager?.getCache(geoHash: "u0fb", completion: { (cache, error) in
                if let _ = error  {
                        XCTAssertTrue(true)
                } else {
                    XCTAssertTrue(false)
                }
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
