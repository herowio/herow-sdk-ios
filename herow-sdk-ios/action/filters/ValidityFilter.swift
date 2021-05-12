//
//  ValidityFilter.swift
//  herow_sdk_ios
//
//  Created by Damien on 27/04/2021.
//

import Foundation
class ValidityFilter :NotificationFilter {
    var timeProvider: TimeProvider
    required init(timeProvider: TimeProvider = TimeProviderAbsolute(), cacheManager: CacheManagerProtocol? = nil) {
        self.timeProvider = timeProvider
    }

    func createNotification(campaign: Campaign, completion:(()->())? = nil) -> Bool {
        let now = Date(timeIntervalSince1970: timeProvider.getTime()).toLocalTime()
        var result = true
        let start = Date(timeIntervalSince1970: campaign.getBegin() / 1000).toLocalTime()
        if start > now {
            result = false
        }
        if let endTime = campaign.getEnd() {
            if endTime == 0 { return true }
            let end = Date(timeIntervalSince1970: endTime / 1000).toLocalTime()
            if end < now {
                result = false
            }
        }
        let can = result ? "CAN" : "CAN NOT"
        GlobalLogger.shared.info("ValidityFilter: \(campaign.getName()) \(can) create notification")
        return result
    }
}
