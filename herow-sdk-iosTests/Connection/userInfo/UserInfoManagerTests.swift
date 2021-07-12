//
//  UserInfoManagerTests.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 16/02/2021.
//

import XCTest
@testable import herow_sdk_ios
class UserInfoManagerTests: XCTestCase, UserInfoListener {
    func onUserInfoUpdate(userInfo: UserInfo) {

    }

    var userInfoManager : UserInfoManager?
    override func setUpWithError() throws {
        let herowDataStorage =  HerowDataStorage(dataHolder:DataHolderUserDefaults(suiteName: "HerowTest"), timeProvider: TimeProviderForTests())
        userInfoManager = UserInfoManager( herowDataStorage: herowDataStorage)
        userInfoManager?.registerListener(listener: self)
        userInfoManager?.reset()
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

    func testSave() throws {
        let customId = "toto@toto.fr"
        let optin =  Optin(type: "type", value: true)
        userInfoManager?.setCustomId(customId)
        userInfoManager?.setOptin(optin:optin)
        userInfoManager?.herowDataHolder.saveUserInfo(APIUserInfo(herowId: "evchefvcfrvcfrv", modifiedDate: Int64(Date().timeIntervalSince1970)))
        XCTAssertTrue(   userInfoManager?.getCustomId() == customId)
        XCTAssertTrue(   userInfoManager?.getOptin().type == optin.type &&   userInfoManager?.getOptin().value == optin.value)
        userInfoManager?.herowDataHolder.saveUserInfoWaitingForUpdate(false)
        if let  isWaitingForUpdate = userInfoManager?.herowDataHolder.userInfoWaitingForUpdate() {
        XCTAssertFalse(isWaitingForUpdate)
          
        }
    }
    func testShouldUpdate() throws {
        let customId = "toto@toto.fr"
        let optin =  Optin(type: "type", value: true)
        userInfoManager?.setCustomId(customId)
        userInfoManager?.setOptin(optin:optin)
        userInfoManager?.herowDataHolder.saveUserInfo(APIUserInfo(herowId: "evchefvcfrvcfrv", modifiedDate: Int64(Date().timeIntervalSince1970)))
        XCTAssertTrue(   userInfoManager?.getCustomId() == customId)
        XCTAssertTrue(   userInfoManager?.getOptin().type == optin.type &&   userInfoManager?.getOptin().value == optin.value)
        let customId2 = "toto2@toto.fr"

        userInfoManager?.setCustomId(customId2)
        if let  isWaitingForUpdate = userInfoManager?.herowDataHolder.userInfoWaitingForUpdate() {
        XCTAssertTrue(isWaitingForUpdate)
            userInfoManager?.herowDataHolder.saveUserInfoWaitingForUpdate(false)
        }

        userInfoManager?.setCustomId(customId)
        if let  isWaitingForUpdate = userInfoManager?.herowDataHolder.userInfoWaitingForUpdate() {
        XCTAssertTrue(isWaitingForUpdate)
            userInfoManager?.herowDataHolder.saveUserInfoWaitingForUpdate(false)
        }

        userInfoManager?.setCustomId(customId)
        if let  isWaitingForUpdate = userInfoManager?.herowDataHolder.userInfoWaitingForUpdate() {
        XCTAssertFalse(isWaitingForUpdate)
            userInfoManager?.herowDataHolder.saveUserInfoWaitingForUpdate(false)
        }
    }


}
