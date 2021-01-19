//
//  BatteryUtils.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 30/08/2019.
//  Copyright © 2019 Connecthings. All rights reserved.
//

import Foundation
import UIKit
public class BatteryUtils {
    public static func getCurrentLevel() -> Int {
        if #available(iOS 12, *) {
            UIDevice.current.isBatteryMonitoringEnabled = true
            return Int(round(UIDevice.current.batteryLevel * 100))
        } else {
            return -1
        }
    }

    public static func getChargingStatus() -> Int {
        if #available(iOS 12, *) {
            UIDevice.current.isBatteryMonitoringEnabled = true
            if UIDevice.current.batteryState == .charging {
                return ChargingStatus.CHARGING_PLUGGED_AC.rawValue
            }
            return ChargingStatus.NOT_CHARGING.rawValue
        } else {
            return ChargingStatus.NOT_CHARGING.rawValue
        }
    }
}
