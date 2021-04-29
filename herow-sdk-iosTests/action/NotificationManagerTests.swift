//
//  NotificationManagerTests.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 28/04/2021.
//

import XCTest
@testable import herow_sdk_ios
class NotificationManagerTests: XCTestCase, UserInfoListener {
    var userInfoManager: UserInfoManager?
    func onUserInfoUpdate(userInfo: UserInfo) {

    }

    let herowDataStorage = HerowDataStorage(dataHolder:DataHolderUserDefaults(suiteName: "HerowTest"))
    var notificationManager = NotificationManager(cacheManager: CacheManager(db: CoreDataManager<HerowZone, HerowAccess, HerowPoi, HerowCampaign, HerowInterval, HerowNotification, HerowCapping>()), notificationCenter: MockNotificationCenter(), herowDataStorage: HerowDataStorage(dataHolder:DataHolderUserDefaults(suiteName: "HerowTest")))
    override func setUpWithError() throws {
        let herowDataStorage = HerowDataStorage(dataHolder:DataHolderUserDefaults(suiteName: "HerowTest"))
         userInfoManager = UserInfoManager(listener: self, herowDataStorage: herowDataStorage)
        userInfoManager?.setCustomId("customID")
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        userInfoManager?.removeCustomId()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDynamic() throws {

        let zone = HerowZone(hash: "ee", lat: 0, lng: 0, radius: 50, campaigns: ["gh"], access: HerowAccess(id: "ee", name: "HerowZoneName", address: "my address"), liveEvent: false)
        let camp = HerowCampaign(id: "gh", company: "hj", name: "jh", createdDate: 1234, modifiedDate: 12345, deleted: false, simpleId: "gg", begin: 0, end: nil, realTimeContent: true, intervals: nil, cappings: [maxNumberNotifications : 3, minTimeBetweenTwoNotifications : 3 * oneDayMilliSeconds], triggers: [String:Int](), daysRecurrence: [String](), recurrenceEnabled: false, tz: "ee", notification: HerowNotification(title: "vente macbook", description: "{{user.customId|default('toi')}}, tu es à {{zone.name|default('zone')}}"), startHour: nil, stopHour: nil)

        var text: String = camp.getNotification()?.getDescription() ?? ""
       text =  notificationManager.computeDynamicContent(text, zone: zone, campaign: camp)
        XCTAssertTrue(text == "customID, tu es à HerowZoneName")
        userInfoManager?.removeCustomId()
        text =  camp.getNotification()?.getDescription() ?? ""
        text =  notificationManager.computeDynamicContent(text, zone: zone, campaign: camp)
        XCTAssertTrue(text == "toi, tu es à HerowZoneName")

        userInfoManager?.setCustomId("customID")
        let zone2 = HerowZone(hash: "ee", lat: 0, lng: 0, radius: 50, campaigns: ["gh"], access: nil, liveEvent: false)
        let camp2 = HerowCampaign(id: "gh", company: "hj", name: "jh", createdDate: 1234, modifiedDate: 12345, deleted: false, simpleId: "gg", begin: 0, end: nil, realTimeContent: true, intervals: nil, cappings: [maxNumberNotifications : 3, minTimeBetweenTwoNotifications : 3 * oneDayMilliSeconds], triggers: [String:Int](), daysRecurrence: [String](), recurrenceEnabled: false, tz: "ee", notification: HerowNotification(title: "vente macbook", description: "{{user.customId|default('toi')}}, tu es à {{zone.name|default('zone')}}"), startHour: nil, stopHour: nil)

       text = camp2.getNotification()?.getDescription() ?? ""
       text =  notificationManager.computeDynamicContent(text, zone: zone2, campaign: camp2)
        XCTAssertTrue(text == "customID, tu es à zone")
        userInfoManager?.removeCustomId()
        text =  camp2.getNotification()?.getDescription() ?? ""
        text =  notificationManager.computeDynamicContent(text, zone: zone2, campaign: camp2)
        XCTAssertTrue(text == "toi, tu es à zone")

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
