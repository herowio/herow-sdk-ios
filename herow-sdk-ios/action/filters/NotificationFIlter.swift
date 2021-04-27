//
//  NotificationFIlter.swift
//  herow_sdk_ios
//
//  Created by Damien on 19/04/2021.
//

import Foundation

 protocol NotificationFilter: AnyObject {
    var timeProvider: TimeProvider {get set}
    init(timeProvider: TimeProvider)
    func createNotification(campaign: Campaign) -> Bool
}


