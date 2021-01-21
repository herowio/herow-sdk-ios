//
//  RadioAccessTechnology.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 02/09/2019.
//  Copyright © 2019 Connecthings. All rights reserved.
//

import Foundation

public enum RadioAccessTechnology: String {
    case gprs = "CTRadioAccessTechnologyGPRS"
    case edge = "CTRadioAccessTechnologyEdge"
    case cdma = "CTRadioAccessTechnologyCDMA1x"

    case hrpd = "CTRadioAccessTechnologyeHRPD"
    case hsdpa = "CTRadioAccessTechnologyHSDPA"
    case hsupa = "CTRadioAccessTechnologyHSUPA"
    case rev0 = "CTRadioAccessTechnologyCDMAEVDORev0"
    case revA = "CTRadioAccessTechnologyCDMAEVDORevA"
    case revB = "CTRadioAccessTechnologyCDMAEVDORevB"
    case wcdma = "CTRadioAccessTechnologyWCDMA"

    case lte = "CTRadioAccessTechnologyLTE"

    public var connectivityType: ConnectivityType {
        switch self {
        case .gprs, .edge, .cdma:
            return ConnectivityType.MOBILE_2G
        case .lte:
            return ConnectivityType.MOBILE_4G
        default:
            return ConnectivityType.MOBILE_3G
        }
    }
}
