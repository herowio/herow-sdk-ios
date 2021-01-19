//
//  LocationManagerCoreLocation.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 16/01/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation
import CoreLocation

public class LocationManagerCoreLocation: NSObject, LocationManager, CLLocationManagerDelegate {

    public var clickAndCollectMode: Bool = false
    var  isUpdatingPosition = false
    var  isUpdatingSignificantChanges = false
    var  isMonitoringRegion = false
    var  isMonitoringVisit = false

    let locationManager: CLLocationManager
    var monitoringListeners: [WeakContainer<ClickAndConnectListener>] = [WeakContainer<ClickAndConnectListener>]()

    public var showsBackgroundLocationIndicator: Bool {
        get {
            if #available(iOS 11.0, *) {
                return self.locationManager.showsBackgroundLocationIndicator
            } else {
                return false
            }
        }
        set(newValue) {
            if #available(iOS 11.0, *) {
                self.locationManager.showsBackgroundLocationIndicator = newValue
            } else {
                // Fallback on earlier versions
            }
        }
    }

    public var location: CLLocation? {
        get {
            return self.locationManager.location
        }
    }

    public var heading: CLHeading? {
        get {
            return self.locationManager.heading
        }
    }

    public var delegate: CLLocationManagerDelegate? {
        get {
            return self.locationManager.delegate
        }
        set(delegate) {
            self.locationManager.delegate = delegate
        }
    }

    public var pausesLocationUpdatesAutomatically: Bool {
        get {
            return self.locationManager.pausesLocationUpdatesAutomatically
        }
        set(pausesLocationUpdatesAutomatically) {
            self.locationManager.pausesLocationUpdatesAutomatically = pausesLocationUpdatesAutomatically
        }
    }

    public var allowsBackgroundLocationUpdates: Bool {
        get {
            return self.locationManager.allowsBackgroundLocationUpdates
        }
        set(allowsBackgroundLocationUpdates) {
            self.locationManager.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
        }
    }

    public var distanceFilter: CLLocationDistance {
        get {
            return self.locationManager.distanceFilter
        }
        set(distanceFilter) {
            self.locationManager.distanceFilter = distanceFilter
        }
    }

    public var desiredAccuracy: CLLocationAccuracy {
        get {
            return self.locationManager.desiredAccuracy
        }
        set(desiredAccuracy) {
            self.locationManager.desiredAccuracy = desiredAccuracy
        }
    }

    public var activityType: CLActivityType {
        get {
            return self.locationManager.activityType
        }
        set(activityType) {
            self.locationManager.activityType = activityType
        }
    }

    public init(_ locationManager: CLLocationManager) {
        self.locationManager = locationManager
        super.init()
        self.updateClickAndCollectState()
    }

    public func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    public func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    public func authorizationStatusString() -> String {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            return "authorizedAlways"
        case .authorizedWhenInUse:
            return "authorizedWhenInUse"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "notDetermined"
        default:
            return "notDetermined"
        }
    }

    public func setIsOnClickAndCollect(_ value: Bool) {
        let userDefault =  UserDefaults.standard
        userDefault.setValue(value, forKey: "isLocationMonitoring")
        userDefault.synchronize()
    }

    public func updateClickAndCollectState() {
        let value = (isMonitoringVisit || isUpdatingPosition || isMonitoringRegion || isUpdatingSignificantChanges) &&  self.clickAndCollectMode
        showsBackgroundLocationIndicator = value
        setIsOnClickAndCollect(value)
        if value {
            didStartClickAndCollect()

        } else {
            didStopClickAndCollect()
        }

    }

     public func getIsOnClickAndCollect() -> Bool {
        UserDefaults.standard.bool(forKey:  "isLocationMonitoring")
    }

    @available(iOS 14.0, *)
    public func accuracyAuthorizationStatus() -> CLAccuracyAuthorization {
        return locationManager.accuracyAuthorization
    }

    public func accuracyAuthorizationStatusString() -> String {
        if #available(iOS 14, *) {
            switch  locationManager.accuracyAuthorization {
            case .fullAccuracy:
                return "fullAccuracy"
            case .reducedAccuracy:
                return "reducedAccuracy"
            default:
                return "notDetermined"
            }
        } else {
            return "fullAccuracy"
        }
    }

    public func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    public func startMonitoring(region: CLRegion) {
        GlobalLogger.shared.debug("startMonitoring in ", region.identifier)
        isMonitoringRegion = true
        updateClickAndCollectState()
        locationManager.startMonitoring(for: region)
    }

    public func stopMonitoring(region: CLRegion) {
        GlobalLogger.shared.debug("stopMonitoring in ", region.identifier)
        isMonitoringRegion = false
        updateClickAndCollectState()
        locationManager.stopMonitoring(for: region)
    }

    public func startRangingBeacons(region: CLBeaconRegion) {
        GlobalLogger.shared.debug("startRangingBeacons in ", region.identifier)
        locationManager.startRangingBeacons(in: region)
    }

    public func stopRangingBeacons(region: CLBeaconRegion) {
        GlobalLogger.shared.debug("stopRanging in ", region.identifier)
        locationManager.stopRangingBeacons(in: region)
    }

    public func getRangedRegions() -> Set<CLRegion> {
        return locationManager.rangedRegions
    }

    public func getMonitoredRegions() -> Set<CLRegion> {
        return locationManager.monitoredRegions
    }

    public func startMonitoringSignificantLocationChanges() {
        if locationServicesEnabled() {

            isUpdatingSignificantChanges = true
            updateClickAndCollectState()
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }

    public func stopMonitoringSignificantLocationChanges() {
        isUpdatingSignificantChanges = false
        updateClickAndCollectState()
        locationManager.stopMonitoringSignificantLocationChanges()
    }

    public func startUpdatingLocation() {
        if locationServicesEnabled() {
            isUpdatingPosition = true
            updateClickAndCollectState()
            locationManager.startUpdatingLocation()
        }
    }

    public func stopUpdatingLocation() {
        isUpdatingPosition = false
        updateClickAndCollectState()
        locationManager.stopUpdatingLocation()
    }

    public func startMonitoringVisits() {
        isMonitoringVisit = true
        updateClickAndCollectState()
        locationManager.startMonitoringVisits()
    }

    public func stopMonitoringVisits() {
        isMonitoringVisit = false
        updateClickAndCollectState()
        locationManager.stopMonitoringVisits()
    }

    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        GlobalLogger.shared.warning("locationManager monitoringDidFailFor \( String(describing: region?.identifier)), withError \(error.localizedDescription)")
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        GlobalLogger.shared.debug("locationManager didChangeAuthorization \( String(describing: status.rawValue))")
    }

    @available(iOS 14.0, *)
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        GlobalLogger.shared.debug("locationManager didChangeAuthorization \( String(describing: CLLocationManager.authorizationStatus().rawValue)) precision \(manager.accuracyAuthorization.rawValue)")
    }

    private func didStartClickAndCollect() {
        for listener in monitoringListeners {
            listener.get()?.didStartClickAndConnect()
        }
    }

    private func didStopClickAndCollect() {
        for listener in monitoringListeners {
            listener.get()?.didStopClickAndConnect()
        }
    }

    @objc public func registerClickAndCollectListener(listener: ClickAndConnectListener) {
        let first = monitoringListeners.first {
            ($0.get() === listener) == true
        }
        if first == nil {
            monitoringListeners.append(WeakContainer<ClickAndConnectListener>(value: listener))
        }
    }

    @objc public func unregisterClickAndCollectListener(listener: ClickAndConnectListener) {
        monitoringListeners = monitoringListeners.filter {
            ($0.get() === listener) == false
        }
    }
}
