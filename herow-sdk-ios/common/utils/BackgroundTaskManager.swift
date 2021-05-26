//
//  BackgroundTaskManager.swift
//  ConnectPlaceGeoDetection
//
//  Created by Connecthings on 19/09/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation
import UIKit
public class BackgroundTaskManager: AppStateDelegate {
    public weak var delegate: BackgroundTaskDelegate?

    let app: UIApplication
    let name: String
    var backgroundTaskId: UIBackgroundTaskIdentifier
    internal private(set) var isOnBackground: Bool
    //In second
    let timeOut: Double
    var timeOutWorkItem: DispatchWorkItem?
    var expirationHandler:(() -> Void)?

    public init(app: UIApplication,
                name: String,
                queue: DispatchQueue? = nil,
                timeOut: Double = 0) {
        self.app = app
        self.name = name
        backgroundTaskId = UIBackgroundTaskIdentifier.invalid
        isOnBackground = false
        self.timeOut = timeOut
    }

    public func isInvalid() -> Bool {
        if isOnBackground {
            return backgroundTaskId == UIBackgroundTaskIdentifier.invalid
        }
        return false
    }

    public func start(_ expirationHandler:(() -> Void)? = nil) {
        if //isOnBackground,
            backgroundTaskId == UIBackgroundTaskIdentifier.invalid {
            self.expirationHandler = expirationHandler
            backgroundTaskId = app.beginBackgroundTask(withName: name, expirationHandler: {
                self.stop()
            })
            DispatchQueue.main.async {
                GlobalLogger.shared.debug("background task \(self.backgroundTaskId) start for \(self.name)")
                GlobalLogger.shared.debug("Background time remaining = \(UIApplication.shared.backgroundTimeRemaining) seconds")
            }
            self.delegate?.onStartBackgroundTask(id: backgroundTaskId, name: name)
        }
    }

    public func updateTimeOut() {
        if timeOut != 0,
          //  isOnBackground,
            backgroundTaskId != UIBackgroundTaskIdentifier.invalid {

            timeOutWorkItem?.cancel()
            timeOutWorkItem = DispatchWorkItem {
                self.stop()
            }
            if let timeOutWorkItem = timeOutWorkItem {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeOut, execute: timeOutWorkItem)
            }
        }
    }

    public func stop() {
        if let timeOutWorkItem = timeOutWorkItem {
            self.timeOutWorkItem = nil
            timeOutWorkItem.cancel()
        }
        if let expirationHandler = expirationHandler {
            self.expirationHandler = nil
            expirationHandler()
        }
        if backgroundTaskId != UIBackgroundTaskIdentifier.invalid {
            GlobalLogger.shared.debug("background task \(backgroundTaskId) end for \(name)")
            self.delegate?.onStopBackgroundTask(id: backgroundTaskId, name: name)
            app.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = UIBackgroundTaskIdentifier.invalid
        }
    }

    public func onAppInBackground() {
        isOnBackground = true
        GlobalLogger.shared.debug("appStateDetector - inBackground \(self)")
    }

    public func onAppInForeground() {
        isOnBackground = false
        stop()
    }
}

public protocol BackgroundTaskDelegate: AnyObject {
    func onStartBackgroundTask(id: UIBackgroundTaskIdentifier, name: String)

    func onStopBackgroundTask(id: UIBackgroundTaskIdentifier, name: String)
}

