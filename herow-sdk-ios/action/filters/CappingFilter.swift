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
        var startHour = 0
        var startMinutes = 0
        //compute beginning of new period
        if let start = campaign.getStartHour() {
            let startComponents = start.components(separatedBy: ":")
            if  startComponents.count == 2  {
                if let newStartHour = Int(startComponents[0]),
                   let newStartMinutes = Int(startComponents[1]) {
                    startHour = newStartHour
                    startMinutes = newStartMinutes
                }
            }
        }
        let now = Date(timeIntervalSince1970: timeProvider.getTime()).toLocalTime()
        let firstRazDate = now.setTime(hour: startHour, min: startMinutes) ?? Date()
        let herowCapping : HerowCapping = (cacheManager.getCapping(id: campaign.getId()) as? HerowCapping) ?? HerowCapping(id: campaign.getId(), razDate: firstRazDate, count: 0)
        var count:Int64 = 0
        var result = false
        if now < herowCapping.getRazDate().toLocalTime() {
            count = herowCapping.getCount()
        } else {
            if  let newRazDate =  herowCapping.getRazDate().addingTimeInterval(resetDelay).setTime(hour: startHour, min: startMinutes) {
                herowCapping.setRazDate(date: newRazDate)
            }

        }
        herowCapping.setCount(count: count + 1)
        cacheManager.saveCapping(herowCapping, completion: nil)
        if count < max {

            result = true
        }
        return result
    }

}
