//
//  RecurencyFilter.swift
//  herow_sdk_ios
//
//  Created by Damien on 26/04/2021.
//

import Foundation
class RecurencyFilter :NotificationFilter {
    var timeProvider: TimeProvider
    private var dateFormatter = DateFormatter()
    required init(timeProvider: TimeProvider = TimeProviderAbsolute()) {
        self.timeProvider = timeProvider
        dateFormatter.dateFormat = "EEEE"
        dateFormatter.locale =  NSLocale(localeIdentifier: "en_EN") as Locale
    }

    func createNotification(campaign: Campaign) -> Bool {
        let now = Date(timeIntervalSince1970: timeProvider.getTime()).toLocalTime()
        let currentDay = dateFormatter.string(from: now).uppercased()
        var result = false
        if let reccurencies = campaign.getDaysRecurrence()?.map({ $0.uppercased()}) {
            if reccurencies.count == 0 {
                result = true
            }
            for  day in reccurencies {
                if day == currentDay {
                    result = true
                }
            }
        }else {
            result = true
        }
        return result
    }
}
