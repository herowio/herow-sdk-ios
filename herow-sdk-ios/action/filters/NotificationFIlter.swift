//
//  NotificationFIlter.swift
//  herow_sdk_ios
//
//  Created by Damien on 19/04/2021.
//

import Foundation

 protocol NotificationFilter: AnyObject {
    var timeProvider: TimeProvider {get set}
    init(timeProvider: TimeProvider, cacheManager: CacheManagerProtocol?)
    func createNotification(campaign: Campaign) -> Bool
}


