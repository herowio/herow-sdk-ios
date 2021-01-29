//
//  PermissionsManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 21/01/2021.
//

import Foundation
import CoreLocation
import AppTrackingTransparency

@objc public enum LocationPermission: Int {
    case whenInUse
    case always
}
@objc public protocol PermissionsManagerProtocol: class {
    func requestIDFA(completion: (()->())?)
    func requestLocation(_ type: LocationPermission, completion: (()->())?)
    func requestActivity( completion: (()->())?)
}
@objc class PermissionsManager: NSObject, PermissionsManagerProtocol  {
    let userInfoManager: UserInfoManagerProtocol
    let locationManager = CLLocationManager()
    let motionManager = MotionActivityManager()
    init(userInfoManager: UserInfoManagerProtocol ) {
        self.userInfoManager = userInfoManager
    }

    func requestIDFA(completion: (()->())? = nil) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                completion?()
            })
        } else {
            completion?()
            // Fallback on earlier versions
        }
    }

    internal func requestWhenInUSeLocation(completion: (()->())?) {
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

    @objc func requestLocation(_ type: LocationPermission, completion: (()->())?) {
        switch type {
        case .whenInUse:
            requestWhenInUSeLocation(completion: completion)
        case .always:
            requestAlwaysLocation(completion: completion)
        }
    }

    @objc func requestActivity( completion: (()->())?) {
        motionManager.requestPermission()
        completion?()

    }

}
