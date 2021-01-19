//
//  MotionStarter.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 12/07/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation
import CoreMotion

public class MotionActivityManager {
    public let motionActivityManager: CMMotionActivityManager
    public let motionOperationQueue: OperationQueue
    public var motionRequestDelegates: [MotionRequestDelegate]

    public init() {
        motionActivityManager = CMMotionActivityManager()
        motionOperationQueue = OperationQueue()
        motionRequestDelegates = []
        askPermissionAtStart()
    }

    public func addMotionRequestDelegate(_ delegate: MotionRequestDelegate) {
        motionRequestDelegates.append(delegate)
    }

    func askPermissionAtStart() {
        let bundle = Bundle(for: TimeProviderRelative.self)
        if let content = FileUtils.loadPlist(bundle) {
            if let askMotionActivityPermissionAtStart =
                content.object(forKey: "askMotionActivityPermissionAtStart") as? Bool {
                if askMotionActivityPermissionAtStart {
                    requestPermission()
                }
            }
        }
    }

    /*
     * function to tell if the framework already promped the user to ask for CoreMotion authorization.
     * Will return true also in the case the core motion features are not available for the device.
     * Thiis function is useful to know if it's useful to request the authorization or not
     */
    /*public func alreadyPromped() -> Bool {
        let status = self.checkMotionAuthStatus()
        return (status != MotionHealthCheckError.notDetermined.rawValue)
            && (status != motionHealthCheckStatusCantBeKnown)
    }*/

    public func granted() -> Bool {
        if #available(iOS 11.0, *),
                CMMotionActivityManager.isActivityAvailable(),
            CMMotionActivityManager.authorizationStatus() == .authorized {
            return true
        }
        return false
    }

    /**
     * Request authorization for CoreMotion related features (Motion Activty, Pedometer, Altitude, SensorRecorder)
     */
    public func requestManualPermission() {
        if #available(iOS 11.0, *),
            CMMotionActivityManager.isActivityAvailable(),
            CMMotionActivityManager.authorizationStatus() == .notDetermined {
            motionActivityManager.queryActivityStarting(from: Date(timeIntervalSinceNow: -5),
                                                        to: Date(),
                                                        to: motionOperationQueue, withHandler: { (_, _) in
                                                            for motionRequestDelegate in self.motionRequestDelegates {
                                                                motionRequestDelegate.onMotionRequest()
                                                            }
            })
        }
    }

    public func requestPermission() {
        if  Bundle.main.object(forInfoDictionaryKey: "NSMotionUsageDescription") != nil {
            requestManualPermission()
        }
    }

    public func startActivityUpdates(_ handler: @escaping CMMotionActivityHandler) {
        motionActivityManager.startActivityUpdates(to: self.motionOperationQueue, withHandler: handler)
    }

    public func stopActivityUpdates() {
        motionActivityManager.stopActivityUpdates()
    }

    public func queryActivityStarting(from: Date,
                                      to: Date,
                                      withHandler handler: @escaping CMMotionActivityQueryHandler) {
        motionActivityManager.queryActivityStarting(from: Date(timeIntervalSinceNow: -5),
                                                    to: Date(),
                                                    to: motionOperationQueue, withHandler: handler)
    }
}
