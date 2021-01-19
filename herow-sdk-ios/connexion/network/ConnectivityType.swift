//
//  ConnectivityType.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 02/09/2019.
//  Copyright © 2019 Connecthings. All rights reserved.
//

import Foundation

// swiftlint:disable identifier_name
public enum ConnectivityType: Int {
    case UNKNOWN = -1
    case OFFLINE = 0
    /**
     * From this link https://en.wikipedia.org/wiki/Evolution-Data_Optimized ..
     * NETWORK_TYPE_EVDO_0 & NETWORK_TYPE_EVDO_A.
     * EV-DO is an evolution of the CDMA2000 (IS-2000) standard that supports high data rates.
     * Where CDMA2000 https://en.wikipedia.org/wiki/CDMA2000 .CDMA2000 is a family of 3G mobile technology
     * standards for sending voice, data, and signaling data between mobile phones and cell sites.
     */
    case MOBILE_2G = 1
    /**
     * For 3g HSDPA, HSPAP(HSPA+) are main network type which are under 3g Network.
     * But from other constants also it will 3g like HSPA,HSDPA etc which are in 3g case.
     * Some cases are added after  testing(real) in device with 3g enable data and speed also matters to
     * decide 3g network type. (@see: https://en.wikipedia.org/wiki/4G#Data_rate_comparison)
     */
    case MOBILE_3G = 2
    /**
     * 4G => LTE (@see: https://en.wikipedia.org/wiki/LTE_(telecommunication))
     */
    case MOBILE_4G = 3
    case WIFI = 4
}
