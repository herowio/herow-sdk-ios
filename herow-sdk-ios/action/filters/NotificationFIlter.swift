//
//  NotificationFIlter.swift
//  herow_sdk_ios
//
//  Created by Damien on 19/04/2021.
//

import Foundation

public protocol NotificationFilter: class {
    func createNotification(campaign: Campaign) -> Bool
}
