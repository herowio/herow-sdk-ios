//
//  FuseManager.swift
//  herow_sdk_ios
//
//  Created by Damien on 15/03/2021.
//

import Foundation
import CoreLocation

@objc public protocol FuseManagerListener: class {
    func onFuseUpdate(_ activated: Bool, location: CLLocation?)
}
class FuseManager: DetectionEngineListener, ResetDelegate {
    func reset() {
        locationCount = 0
        lastLocationTime = 0
        save()
    }
    static  let timeWindow = Double(5 * 60)
    static  let countLimit = 50
    let dateKey = "FuseManagerDateTime"
    let countKey = "FuseManagerCount"
    private var dataHolder: DataHolder
    private var lastLocationTime: Double = 0
    private var locationCount: Int = 0
    private var timeProvider: TimeProvider
    var activated = false
    internal var listeners: [WeakContainer<FuseManagerListener>] = [WeakContainer<FuseManagerListener>]()
    private func load() {
        lastLocationTime = self.dataHolder.getDouble(key: dateKey)
        locationCount = self.dataHolder.getInt(key: countKey)
    }

    private func save() {
        self.dataHolder.putInt(key: countKey, value: locationCount)
        self.dataHolder.putDouble(key: dateKey, value: lastLocationTime)
    }

    init(dataHolder: DataHolder, timeProvider: TimeProvider = TimeProviderAbsolute()) {
        self.dataHolder = dataHolder
        self.timeProvider = timeProvider
        load()
    }
    func onLocationUpdate(_ location: CLLocation, from: UpdateType = .undefined) {
        load()
        let now = timeProvider.getTime()
        if locationCount == 0 {
            lastLocationTime = now
        }
        if now - lastLocationTime < FuseManager.timeWindow {
            locationCount = locationCount + 1
        } else {
            reset() 
        }
        let newValue = (locationCount > FuseManager.countLimit)
        if self.activated != newValue {

            for listner in listeners {
                listner.get()?.onFuseUpdate(newValue, location: location)
            }
        }
        activated = newValue

        save()
    }

    @objc public func registerFuseManagerListener(listener: FuseManagerListener) {
        let first = listeners.first {
            ($0.get() === listener) == true
        }
        if first == nil {
            listeners.append(WeakContainer<FuseManagerListener>(value: listener))
        }
    }

    @objc public func unregisterFuseManagerListener(listener: FuseManagerListener) {
        listeners = listeners.filter {
            ($0.get() === listener) == false
        }
    }

   internal  func isActivated() -> Bool {
        GlobalLogger.shared.debug("FuseManager - activated = \(activated)")
        return activated
    }

}
