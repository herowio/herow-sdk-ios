//
//  APIWorkerTest.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 12/02/2021.
//

import XCTest
@testable import herow_sdk_ios
class APIWorkerTest: XCTestCase {
    var user: User?
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }



    private func tokenParams() -> Data {
        var result: Data?
        let encoder = JSONEncoder()

        do {
            let params = [Parameters.username:"login",
                          Parameters.password: "password",
                          Parameters.clientId:  "credentials.clientId",
                          Parameters.clientSecret: "credentials.clientSecret",
                         // Parameters.redirectUri: "credentials.redirectURI",
                          Parameters.grantType : "password"]

            result = try encoder.encode(params)
            if let result = result {
            GlobalLogger.shared.debug("APIManager - token infos to send: \(String(decoding: result, as: UTF8.self))")
            }

        } catch {
            print("error while encoding userInfo : \(error.localizedDescription)")
        }
        return result ?? Data()

    }

    func testFailBadRoute() throws {
        let apiWorker = APIWorker<APIToken>(urlType: .badURL, endPoint: .token)
        apiWorker.setUrlType(.badURL)
        let testFailExpectation = expectation(description: "testFailExpectation")
        apiWorker.postData(param: tokenParams(), completion: { (token, error) in
            if let error = error  {
                switch error {
                case .badUrl:
                    XCTAssertTrue(true)
                default:
                    XCTAssertTrue(false)
                }
            } else {
                XCTAssertTrue(false)
            }
            testFailExpectation.fulfill()
        })
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func testFailBadSerialization() throws {
        let apiWorker = APIWorker<String>(urlType: .test, endPoint: .token)
        apiWorker.setUrlType(.test)
        let testFailExpectation = expectation(description: "testFailExpectation")
        apiWorker.headers = [ Headers.contentType: Headers.Values.contentTypeJson,
                              Headers.version: "0.0.0",
                              Headers.deviceId: "00000",
                              Headers.sdk: "test"
             ]
        apiWorker.postData(param: tokenParams(), completion: { (token, error) in
            if let error = error {
                switch error {
                case .serialization:
                    XCTAssertTrue(true)
                default:
                    XCTAssertTrue(false)
                }
            } else {
                XCTAssertTrue(false)
            }
            testFailExpectation.fulfill()
        })
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func testSuccess() throws {
        let apiWorker = APIWorker<APIToken>(urlType: .test, endPoint: .token)
        apiWorker.setUrlType(.test)
        let testFailExpectation = expectation(description: "testFailExpectation")
        apiWorker.headers = [ Headers.contentType: Headers.Values.contentTypeJson,
                              Headers.version: "0.0.0",
                              Headers.deviceId: "00000",
                              Headers.sdk: "test"
             ]
        apiWorker.postData(param: tokenParams(), completion: { (token, error) in
            if let _ = error  {
                    XCTAssertTrue(false)
            } else {
                XCTAssertTrue(true)
            }
            testFailExpectation.fulfill()
        })
        waitForExpectations(timeout: 5) { error in
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
