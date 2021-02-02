//
//  HerowDataUtils.swift
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

// The MIT License (MIT)
//
// Copyright (c) 2015 Isuru Nanayakkara
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


// swiftlint:disable identifier_name
let ReachabilityStatusChangedNotification = "ReachabilityStatusChangedNotification"

public enum ReachabilityType: CustomStringConvertible {
    case wwan
    case wiFi

    public var description: String {
        switch self {
            case .wwan:
                return "WWAN"
            case .wiFi:
                return "WiFi"
        }
    }
}

public enum ReachabilityStatus: CustomStringConvertible {
    case offline
    case online(ReachabilityType)
    case unknown

    public var description: String {
        switch self {
            case .offline: return "Offline"
            case .online(let type): return "Online (\(type))"
            case .unknown: return "Unknown"
        }
    }
}

open class Reach {
    public init() {
    }

    public func connectionStatus() -> ReachabilityStatus {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
            }
        }) else {
            return .unknown
        }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .unknown
        }

        return ReachabilityStatus(reachabilityFlags: flags)
    }

    func monitorReachabilityChanges() {
        let host = "google.com"
        var context = SCNetworkReachabilityContext(version: 0, info: nil,
                                                   retain: nil, release: nil,
                                                   copyDescription: nil)
        let reachability = SCNetworkReachabilityCreateWithName(nil, host)!

        SCNetworkReachabilitySetCallback(reachability, { (_, flags, _) in
            let status = ReachabilityStatus(reachabilityFlags: flags)
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: ReachabilityStatusChangedNotification),
                                            object: nil,
                                            userInfo: ["Status": status.description])
        }, &context)

        SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
    }
}

public class Reachability {
    public class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0,
                                      sin_family: 0,
                                      sin_port: 0,
                                      sin_addr: in_addr(s_addr: 0),
                                      sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }

        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }

        /* ------- Only Working for WIFI
         let isReachable = flags == .reachable
         let needsConnection = flags == .connectionRequired
         return isReachable && !needsConnection
         */

        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)

        return ret
    }
}

extension ReachabilityStatus {
    fileprivate init(reachabilityFlags flags: SCNetworkReachabilityFlags) {
        let connectionRequired = flags.contains(.connectionRequired)
        let isReachable = flags.contains(.reachable)
        let isWWAN = flags.contains(.isWWAN)

        if !connectionRequired && isReachable {
            if isWWAN {
                self = .online(.wwan)
            } else {
                self = .online(.wiFi)
            }
        } else {
            self =  .offline
        }
    }
}

