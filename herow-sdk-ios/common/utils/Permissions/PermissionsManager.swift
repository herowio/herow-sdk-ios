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
@objc public protocol PermissionsManagerProtocol: AnyObject {

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
@objc public class PermissionsManager: NSObject, PermissionsManagerProtocol , CLLocationManagerDelegate {
    let userInfoManager: UserInfoManagerProtocol
    let locationManager = CLLocationManager()
    let motionManager = MotionActivityManager()
    init(userInfoManager: UserInfoManagerProtocol ) {
        self.userInfoManager = userInfoManager
        super.init()
        self.locationManager.delegate = self
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

    //MARK location delegate

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        GlobalLogger.shared.debug("locationManager didChangeAuthorization \( String(describing: status.rawValue))")
        didChangeAuthorization()
    }

    @available(iOS 14.0, *)
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        GlobalLogger.shared.debug("locationManager didChangeAuthorization \( String(describing: CLLocationManager.authorizationStatus().rawValue)) precision \(manager.accuracyAuthorization.rawValue)")
        didChangeAuthorization()
    }


    func didChangeAuthorization() {
        var state : LocationOptinStatusEnum = .NOT_DETERMINED
        var precision : LocationOptinPrecisionEnum = .FINE

        let iosState = locationManager.authorizationStatus()
        switch iosState {
        case .notDetermined:
            state = .NOT_DETERMINED
        case .restricted:
            state = .NOT_DETERMINED
        case .denied:
            state = .DENIED
        case .authorizedAlways:
            state = .ALWAYS
        case .authorizedWhenInUse:
            state = .WHILE_IN_USE
        case .authorized:
            state = .WHILE_IN_USE
        @unknown default:
            fatalError()
        }

        if #available(iOS 14.0, *) {
            let precisionIOSState = locationManager.accuracyAuthorizationStatus()
            switch precisionIOSState {
            case .fullAccuracy:
                precision = .FINE
            case .reducedAccuracy:
                precision = .COARSE
            @unknown default:
                fatalError()
            }
        }

        let optin = LocationOptin(status: state.rawValue, precision: precision.rawValue)

        self.userInfoManager.setLocOptin(optin: optin)


    }

}
