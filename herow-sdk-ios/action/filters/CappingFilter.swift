//
//  CappingFilter.swift
//  herow_sdk_ios
//
//  Created by Damien on 27/04/2021.
//

import Foundation
let oneDayMilliSeconds = 86400000
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

    func createNotification(campaign: Campaign, completion:(()->())? = nil) -> Bool {
        guard let cacheManager = self.cacheManager, let capping = campaign.getCappings(), let maxCapping = capping[maxNumberNotifications] else {
            return true
        }
        let  resetDelay = max(Double(capping[minTimeBetweenTwoNotifications] ?? oneDayMilliSeconds ) / 1000,  Double(oneDaySeconds))
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
        var firstRazDate = Date().setTime(hour: startHour, min: startMinutes) ?? Date()
        if ( resetDelay > Double(oneDayMilliSeconds / 1000)) {
            firstRazDate = now.addingTimeInterval(resetDelay).setTime(hour: startHour, min: startMinutes) ?? Date()
        } else {
            firstRazDate = now.tomorrow().setTime(hour: startHour, min: startMinutes) ?? Date()
        }
        let herowCapping : HerowCapping = (cacheManager.getCapping(id: campaign.getId()) as? HerowCapping) ?? HerowCapping(id: campaign.getId(), razDate: firstRazDate, count: 0)
        var count:Int64 = Int64.max
        var result = false
        if now < herowCapping.getRazDate() {
            count = herowCapping.getCount()
        } else {
            count = 0
            if  let newRazDate =  herowCapping.getRazDate().addingTimeInterval(resetDelay).setTime(hour: startHour, min: startMinutes) {
                herowCapping.setRazDate(date: newRazDate)
            }
        }
        herowCapping.setCount(count: min(count + 1,Int64(maxCapping)))
        cacheManager.saveCapping(herowCapping, completion: {
            completion?()
        })
        if count < maxCapping {
            result = true
        }
        return result
    }
}
