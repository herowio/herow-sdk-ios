//
//  ChargingStatus.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 30/08/2019.
//  Copyright © 2019 Connecthings. All rights reserved.
//

import Foundation

// swiftlint:disable identifier_name
public enum ChargingStatus: Int {
    case NOT_CHARGING = 0
    case CHARGING_PLUGGED_AC = 1
    case CHARGING_PLUGGED_USB = 2
    case CHARGING_PLUGGED_WIRELESS = 3
}
