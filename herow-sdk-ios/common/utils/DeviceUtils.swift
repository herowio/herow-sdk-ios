//
//  DeviceUtils.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 30/08/2019.
//  Copyright © 2019 Connecthings. All rights reserved.
//

import Foundation
import Network
import UIKit

public class DeviceUtils {
    @available(iOS 12.0, *)
    public static var isAirplaneModeActive = AtomicBoolean()

    /**
     * WARNING If airplane mode and wifi is active then path.availableInterfaces is not empty, because it's returning [en0]
     * @see: https://stackoverflow.com/questions/4804398/detect-airplane-mode-on-ios?noredirect=1&lq=1
     */
    @available(iOS 12.0, *)
    public static func startAirplaneModeMonitoring() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.availableInterfaces.count == 0 {
                isAirplaneModeActive.val = true
            } else {
                isAirplaneModeActive.val = false
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    static func deviceID() -> String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
}
