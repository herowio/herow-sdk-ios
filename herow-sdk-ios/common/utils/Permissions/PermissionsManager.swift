//
//  PermissionsManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 21/01/2021.
//

import Foundation
import CoreLocation
import AppTrackingTransparency
import UserNotifications
@objc public enum LocationPermission: Int {
    case whenInUse
    case always
}
@objc public protocol PermissionsManagerProtocol: class {

    func requestIDFA(completion: (()->())?)
    func requestLocation(_ type: LocationPermission, completion: (()->())?)
    func requestActivity( completion: (()->())?)
    func requestNotificationPermission ( completion: ((Bool, Error?)->())?)
}

extension PermissionsManagerProtocol {
    public func requestAllPermissions(_ type: LocationPermission = .whenInUse, completion: (()->())?) {
        self.requestIDFA() {
            self.requestLocation(.whenInUse) {
                self.requestNotificationPermission { _, _ in
                    completion?()
                }
            }
        }
    }
}
@objc public class PermissionsManager: NSObject, PermissionsManagerProtocol  {
    let userInfoManager: UserInfoManagerProtocol
    let locationManager = CLLocationManager()
    let motionManager = MotionActivityManager()
    init(userInfoManager: UserInfoManagerProtocol ) {
        self.userInfoManager = userInfoManager
    }

   @objc public func requestIDFA(completion: (()->())? = nil) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                completion?()
            })
        } else {
            completion?()
            // Fallback on earlier versions
        }
    }

    internal func requestWhenInUseLocation(completion: (()->())?) {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        }
        completion?()
    }

    internal func requestAlwaysLocation(completion: (()->())?) {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        }
        completion?()
    }

    @objc public  func requestLocation(_ type: LocationPermission, completion: (()->())?) {
        switch type {
        case .whenInUse:
            requestWhenInUseLocation(completion: completion)
        case .always:
            requestAlwaysLocation(completion: completion)
        }
    }

    @objc public func requestActivity( completion: (()->())?) {
        motionManager.requestPermission()
        completion?()

    }

    @objc public func requestNotificationPermission ( completion: ((Bool, Error?)->())?) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            completion?(granted, error)
        }
    }
}
