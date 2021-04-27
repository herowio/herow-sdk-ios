//
//  CappingFilter.swift
//  herow_sdk_ios
//
//  Created by Damien on 27/04/2021.
//

import Foundation
let oneDaySeconds = 86400
let maxNumberNotifications = "maxNumberNotifications"
let minTimeBetweenTwoNotifications = "minTimeBetweenTwoNotifications"
class CappingFilter :NotificationFilter {
    var timeProvider: TimeProvider
    var cacheManager : CacheManagerProtocol?

    required init(timeProvider: TimeProvider, cacheManager: CacheManagerProtocol?) {
        self.cacheManager = cacheManager
        self.timeProvider = timeProvider
    }

    func createNotification(campaign: Campaign) -> Bool {

        guard let cacheManager = self.cacheManager, let capping = campaign.getCappings(), let max = capping[maxNumberNotifications] else {
            return true
        }
        let resetDelay = Double(capping[minTimeBetweenTwoNotifications] ?? oneDaySeconds ) / 1000

        let now = Date(timeIntervalSince1970: timeProvider.getTime()).toLocalTime()
        let herowCapping : HerowCapping = (cacheManager.getCapping(id: campaign.getId()) as? HerowCapping) ?? HerowCapping(id: campaign.getId(), razDate: Date(), count: 0)
//TODO  compute delay to raz
        let count = now < herowCapping.getRazDate() ? 0 :  herowCapping.getCount()
            if count < max {
                herowCapping.setCount(count: count + 1)
                cacheManager.saveCapping(herowCapping, completion: nil)
                return true
            }
            return false

    }


}
