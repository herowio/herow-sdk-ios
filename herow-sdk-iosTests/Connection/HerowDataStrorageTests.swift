//
//  HerowDataStrorageTests.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 15/02/2021.
//

import XCTest
@testable import herow_sdk_ios
class HerowDataStrorageTests: XCTestCase {
    var herowDataStorage =  HerowDataStorage(dataHolder:DataHolderUserDefaults(suiteName: "Test"), timeProvider: TimeProviderForTests())

    override func setUpWithError() throws {
        herowDataStorage.reset()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testToken() throws {
        let expirationDate = Date(timeIntervalSinceNow: 1000)
        herowDataStorage.saveToken(APIToken(accessToken: "guyevfvhr", expiresIn: 0, expirationDate: expirationDate))
        XCTAssertFalse( herowDataStorage.tokenIsExpired())
        let timeProvider = TimeProviderForTests()
        timeProvider.addingTimeInterval(timeInterval: 2000)
        herowDataStorage =  HerowDataStorage(dataHolder:DataHolderUserDefaults(suiteName: "Test"), timeProvider: timeProvider )
        XCTAssertTrue(herowDataStorage.tokenIsExpired())
    }

    func testConfig() throws {
        herowDataStorage.saveConfig(APIConfig(cacheInterval: 1000, configInterval: 1000, enabled: true))
        XCTAssertFalse( herowDataStorage.shouldGetConfig())
        let timeProvider = TimeProviderForTests()
        timeProvider.addingTimeInterval(timeInterval: 2000)
        herowDataStorage =  HerowDataStorage(dataHolder:DataHolderUserDefaults(suiteName: "Test"), timeProvider: timeProvider )
        XCTAssertTrue( herowDataStorage.shouldGetConfig())
    }

    func testCache() throws {
        let hash = "azerty"
        let otherHash = "ertyu"
        let lastFetchDate =  Date(timeIntervalSinceNow: 0)
        let lastModified =  Date(timeIntervalSinceNow:  -3000)
        herowDataStorage.saveConfig(APIConfig(cacheInterval: 1000, configInterval:10000000, enabled: true))
        herowDataStorage.saveLastCacheFetchDate(lastFetchDate)
        herowDataStorage.saveLastCacheModifiedDate(lastModified)
        herowDataStorage.setLastGeohash(hash)
        XCTAssertFalse( herowDataStorage.shouldGetCache(for: hash))
        XCTAssertTrue( herowDataStorage.shouldGetCache(for: otherHash))
        let timeProvider = TimeProviderForTests()
        timeProvider.addingTimeInterval(timeInterval: 20000)
        herowDataStorage =  HerowDataStorage(dataHolder:DataHolderUserDefaults(suiteName: "Test"), timeProvider: timeProvider )
        XCTAssertTrue(herowDataStorage.shouldGetCache(for: hash))
        timeProvider.updateNow()
        herowDataStorage =  HerowDataStorage(dataHolder:DataHolderUserDefaults(suiteName: "Test"), timeProvider: timeProvider )
        XCTAssertFalse(herowDataStorage.shouldGetCache(for: hash))
        herowDataStorage.saveLastCacheModifiedDate(Date())
        XCTAssertTrue(herowDataStorage.shouldGetCache(for: hash))
        herowDataStorage.saveLastCacheModifiedDate(lastModified)
        herowDataStorage.setLastGeohash(otherHash)
        XCTAssertFalse(herowDataStorage.shouldGetCache(for: otherHash))
        herowDataStorage.reset()
        XCTAssertTrue(herowDataStorage.shouldGetCache(for: otherHash))

    }

    func testReset() throws {
        let hash = "azerty"
        let lastFetchDate =  Date(timeIntervalSinceNow: 0)
        let lastModified =  Date(timeIntervalSinceNow:  -3000)
        herowDataStorage.saveConfig(APIConfig(cacheInterval: 1000, configInterval:10000000, enabled: true))
        herowDataStorage.saveLastCacheFetchDate(lastFetchDate)
        herowDataStorage.saveLastCacheModifiedDate(lastModified)
        herowDataStorage.setLastGeohash(hash)
        XCTAssertFalse( herowDataStorage.shouldGetCache(for: hash))
        XCTAssertFalse( herowDataStorage.shouldGetConfig())
        herowDataStorage.reset()
        XCTAssertTrue( herowDataStorage.shouldGetCache(for: hash))
        XCTAssertTrue( herowDataStorage.shouldGetConfig())

    }

    func testUserInfo() throws {
        let date = Date()
        let userInfoToTest = APIUserInfo(herowId: "ABCDEF", modifiedDate: Int64(date.timeIntervalSince1970))
        herowDataStorage.saveUserInfo(userInfoToTest)
        let userInfo = herowDataStorage.getUserInfo()
        XCTAssertTrue( userInfo?.herowId == userInfoToTest.herowId)
        XCTAssertTrue( herowDataStorage.getHerowId() == userInfoToTest.herowId)
    }

    func testSave() throws {
        let customId = "toto@toto.fr"
        let idfv = "dvcucvuvchufvchfcvhufvcu"
        let idfa = "krjgrivbiurbvijrfbvjifrbvji"
        let lang = "fr"
        let offset = 3600
        let optin =  Optin(type: "type", value: true)
        herowDataStorage.setCustomId(customId)
        herowDataStorage.setIDFV(idfv)
        herowDataStorage.setIDFA(idfa)
        herowDataStorage.setLang(lang)
        herowDataStorage.setOffset(offset)
        herowDataStorage.setOptin(optin:optin)
        XCTAssertTrue( herowDataStorage.getCustomId() == customId)
        XCTAssertTrue( herowDataStorage.getIDFV() == idfv)
        XCTAssertTrue( herowDataStorage.getIDFA() == idfa)
        XCTAssertTrue( herowDataStorage.getLang() == lang)
        XCTAssertTrue( herowDataStorage.getOptin().type == optin.type && herowDataStorage.getOptin().value == optin.value)
        XCTAssertTrue( herowDataStorage.getOffset() == offset)

    }



    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
