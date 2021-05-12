//
//  TimeSlotFilter.swift
//  herow_sdk_ios
//
//  Created by Damien on 26/04/2021.
//

import Foundation


class TimeSlotFilter: NotificationFilter {
    var timeProvider: TimeProvider
    required init(timeProvider: TimeProvider = TimeProviderAbsolute(), cacheManager: CacheManagerProtocol? = nil) {
        self.timeProvider = timeProvider
    }

    func createNotification(campaign: Campaign, completion:(()->())? = nil) -> Bool {
        let now = timeProvider.getDate().toLocalTime()
        print("now is : \(now)")
        if let start = campaign.getStartHour(), let end = campaign.getStopHour() {
            let startComponents = start.components(separatedBy: ":")
            let endComponents = end.components(separatedBy: ":")
            guard startComponents.count == 2 && endComponents.count == 2 else {
                return true
            }
            if let startHour = Int(startComponents[0]),
               let startMinutes = Int(startComponents[1]),
               let stopHour = Int(endComponents[0]),
               let stopMinutes = Int(endComponents[1]) {
                if  let startHour = now.setTime(hour: startHour, min: startMinutes)
                    , let stopHour = now.setTime(hour: stopHour, min: stopMinutes) {
                    let result = now > startHour && now < stopHour
                    print("startHour is : \(startHour)")
                    print("stopHour is : \(stopHour)")
                    print(" now > startHour && now < stopHour is : \(result)")
                    if result {
                        GlobalLogger.shared.info("TimeSlotFilter: \(campaign.getName()) CAN create notification  slot date: \(now) startDate: \(startHour) stopDate: \(stopHour)")
                    } else {
                        GlobalLogger.shared.info("TimeSlotFilter: \(campaign.getName()) CAN NOT create notification  slot date: \(now) startDate: \(startHour) stopDate: \(stopHour)")
                    }
                    return result
                }
            }
        }
        GlobalLogger.shared.info("TimeSlotFilter: can create notification no slot)")
        return true
    }


}
