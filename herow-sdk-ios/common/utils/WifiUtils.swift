//
//  NetworkUtils.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 13/02/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation
import SystemConfiguration

/**
 * Manages to check if the wifi (hardware) is enable, don't give any information
 * about the connectivity. To do this, we use a "hack". When there's TWO interfaces
 * reported by getifaddrs() with the name "awdl0" then WiFi is enabled. Just one and it's disabled.
 * If you're using the Command Center, in iOS 11, that's only "soft off." The wifi is disable temporary.
 * It'll turn it self back on by the next morning. "Hard off" only happens when turning off via Settings app.
 * @see https://stackoverflow.com/questions/41969989/better-way-to-detect-wifi-enabled-disabled-on-ios
 */
open class WifiUtils {
    public init() {
    }

    public func isWifiEnabled() -> Bool {
        let set = NSCountedSet()
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                let flags = Int32(ptr!.pointee.ifa_flags)
                let name = String(validatingUTF8: ptr!.pointee.ifa_name)
                if (flags & IFF_UP) == IFF_UP {
                    set.add(name ?? "")
                }
            }
            freeifaddrs(ifaddr)
        }
        return set.count(for: "awdl0") > 1 ? true : false
    }
}
