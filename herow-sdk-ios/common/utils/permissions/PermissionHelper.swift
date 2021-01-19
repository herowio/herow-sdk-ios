//
//  PermissionHelper.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 13/12/2019.
//  Copyright © 2019 Connecthings. All rights reserved.
//

import Foundation
import CoreLocation
import PromiseKit
import UserNotifications

public class PermissionHelper {

    public static let instance = PermissionHelper()
    public var isMocking: Bool = false
    public var mockingStatus: String = "notDetermined"
    public static func extractLocationStatus(_ locationStatus: CLAuthorizationStatus) -> String {
        switch locationStatus {
        case .authorizedAlways:
            return "authorizedAlways"
        case .authorizedWhenInUse:
            return "authorizedWhenInUse"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .notDetermined:
            return "notDetermined"
        @unknown default:
            return "notDetermined"
        }
    }

    @available(iOS 14.0, *)
    public  static func extractAccuracyAuthorizationStatus(_ accuracyAuthorizationStatus: CLAccuracyAuthorization) -> String {
        switch  accuracyAuthorizationStatus {
        case .fullAccuracy:
            return "fullAccuracy"
        case .reducedAccuracy:
            return "reducedAccuracy"
        default:
            return "notDetermined"
        }
    }

    public static func getNotificationsStatus() -> Promise<String> {

        if PermissionHelper.instance.isMocking == true {
            return Promise<String> { seal in  seal.fulfill(PermissionHelper.instance.mockingStatus)}
        }
        return Promise<String> { seal in
            if #available(iOS 10.0, *) {
                let current =  UNUserNotificationCenter.current()
                current.getNotificationSettings(completionHandler: { (settings) in
                    if settings.authorizationStatus == .notDetermined {
                        seal.fulfill("notDetermined")
                    }
                    if settings.authorizationStatus == .denied {
                        seal.fulfill("denied")
                    }
                    if settings.authorizationStatus == .authorized {
                        seal.fulfill("granted")
                    }
                })
            } else {
                if UIApplication.shared.isRegisteredForRemoteNotifications {
                    seal.fulfill("granted")
                } else {
                    seal.fulfill("notDetermined")
                }
            }
        }
    }

    public static func getNotificationsStatusAsBoolean() -> Promise<Bool?> {
        return Promise<Bool?> { seal in
            _ = getNotificationsStatus().done { notificationStatus in
                return seal.fulfill(getNotificationStatusAsBoolean(notificationStatus))
            }
        }
    }

    public static func getNotificationStatusAsBoolean(_ notificationStatus: String) -> Bool? {
        if notificationStatus == "granted" {
            return true
        } else if notificationStatus == "denied" {
            return false
        }
        return nil
    }
}
