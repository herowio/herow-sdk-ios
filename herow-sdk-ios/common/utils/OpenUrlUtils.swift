//
//  OpenUrlUtils.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 28/09/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation
import UIKit
@objc public class OpenUrlUtils: NSObject {

    public static func openApplicationSettings() -> Bool {
        let url = URL(string: UIApplication.openSettingsURLString)
        return openUrl(url)
    }

    public static func openBluetoothPhoneSettings() -> Bool {
        let url = URL(string: UIApplication.openSettingsURLString + "root=Bluetooth")
        return openUrl(url)
    }

    public static func openUrl(_ url: URL?, handler: ((Bool) -> Swift.Void)? = nil) -> Bool {
        if let url: URL = url,
            UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, completionHandler: handler)
                } else {
                    UIApplication.shared.openURL(url)
                }
                return true
        }
        return false
    }
}
