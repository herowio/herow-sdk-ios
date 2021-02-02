//
//  DetectionEngine.swift
//  herow-sdk-ios
//
//  Created by Damien on 27/01/2021.
//

import Foundation
import CoreLocation

@objc public protocol DetectionEngineListener: class {
    func onLocationUpdate(_ location: CLLocation)
    
}


public class DetectionEngine: NSObject, LocationManager, CLLocationManagerDelegate, ConfigListener {

    var isUpdatingPosition = false
    var isUpdatingSignificantChanges = false
    var isMonitoringRegion = false
    var isMonitoringVisit = false
    let timeIntervalLimit: TimeInterval = 2 * 60 * 60 // 2 hours
    let dataHolder =  DataHolderUserDefaults(suiteName: "LocationManagerCoreLocation")
    let locationManager: CLLocationManager
    var lastLocation: CLLocation?
    var monitoringListeners: [WeakContainer<ClickAndConnectListener>] = [WeakContainer<ClickAndConnectListener>]()
    var detectionListners: [WeakContainer<DetectionEngineListener>] = [WeakContainer<DetectionEngineListener>]()

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

    public func getMonitoredRegions() -> Set<CLRegion> {
        return self.locationManager.monitoredRegions
    }

    public init(_ locationManager: CLLocationManager) {
        self.locationManager = locationManager
        super.init()
        self.updateClickAndCollectState()
        self.locationManager.delegate = self
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

            self.dataHolder.putBoolean(key: "isLocationMonitoring", value: value)
            self.dataHolder.apply()

    }

    private func setLastClickAndCollectActivationDate(_ value: Date?) {

        guard let value = value else {
            return dataHolder.remove(key: "lastClickAndCollectActivationDate")
        }

            self.dataHolder.putDate(key: "lastClickAndCollectActivationDate", value: value)
            self.dataHolder.apply()



    }

    private func getLastClickAndCollectActivationDate() -> Date? {

        return dataHolder.getDate(key: "lastClickAndCollectActivationDate")

    }

    private func checkLastClickAndCollectActivationDate() -> Bool {

        guard let date = getLastClickAndCollectActivationDate() else {
             return true
        }
        return Date() < Date(timeInterval: timeIntervalLimit, since: date)
    }


    private func checkClickAndCollectMode() -> Bool {

        let value = (isMonitoringVisit || isUpdatingPosition || isMonitoringRegion || isUpdatingSignificantChanges) &&   getIsOnClickAndCollect()
        let result = value && checkLastClickAndCollectActivationDate()
        showsBackgroundLocationIndicator = result
            setIsOnClickAndCollect(result)


        return value
    }
    public func updateClickAndCollectState() {
        if checkClickAndCollectMode() {
            if getLastClickAndCollectActivationDate() == nil {
                setLastClickAndCollectActivationDate(Date())
                didStartClickAndCollect()
            }
        } else {
            if getLastClickAndCollectActivationDate() != nil {
                setLastClickAndCollectActivationDate(nil)
                didStopClickAndCollect()
            }
        }
    }

     public func getIsOnClickAndCollect() -> Bool {



        return dataHolder.getBoolean(key: "isLocationMonitoring")
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

    @objc public func registerDetectionListener(listener: DetectionEngineListener) {
        let first = detectionListners.first {
            ($0.get() === listener) == true
        }
        if first == nil {
            detectionListners.append(WeakContainer<DetectionEngineListener>(value: listener))
        }
    }

    @objc public func unregisterDetectionListener(listener: DetectionEngineListener) {
        detectionListners = detectionListners.filter {
            ($0.get() === listener) == false
        }
    }

    func dispatchLocation(_ location: CLLocation) {

        var skip = false
        var distance = 0.0
        if let lastLocation = self.lastLocation {

            distance = lastLocation.distance(from: location)
            skip = distance < 5

        }
        if skip == false {
            self.lastLocation = location
            GlobalLogger.shared.debug("DetectionEngine - dispatchLocation : \(location) DISTANCE FROM LAST : \(distance)")
            for listener in  detectionListners {
                listener.get()?.onLocationUpdate(location)
            }
        } else {
            GlobalLogger.shared.debug("DetectionEngine - skip location DISTANCE FROM LAST : \(distance)")
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = manager.location {
            GlobalLogger.shared.debug("didUpdate - manager location: \(location.coordinate.latitude),"
                + "\(location.coordinate.longitude) - \(location.timestamp)")
        }
        if  let location: CLLocation =  locations.last {
            GlobalLogger.shared.debug("didUpdate - last location: \(location.coordinate.latitude),"
                + "\(location.coordinate.longitude) - \(location.timestamp)")
            dispatchLocation(location)
        }
    }

    func extractLocationAfterRegionUpdate() {
            if let location = locationManager.location {
                GlobalLogger.shared.debug("extractLocationAfterRegionUpdate - \(location.coordinate.latitude), \(location.coordinate.longitude)")
                dispatchLocation(location)
            }
    }

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        GlobalLogger.shared.debug("enter in region \(region) - start updating location")
        if LocationUtils.isGeofenceRegion(region) {
            extractLocationAfterRegionUpdate()
        } else {
            GlobalLogger.shared.debug("it's not a geofence region - we do not extract a location")
        }
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        GlobalLogger.shared.debug("exit from region \(region) - start updating location")
        if LocationUtils.isGeofenceRegion(region) {
            extractLocationAfterRegionUpdate()
        } else {
             GlobalLogger.shared.debug("it's not a geofence region - we do not extract a location")
        }
    }

    func didRecievedConfig(_ config: APIConfig) {
        if config.enabled {
            startWorking()
        } else {
            stopWorking()
        }
    }

    func startWorking() {
        self.startUpdatingLocation()
        self.startMonitoringSignificantLocationChanges()
    }

    func stopWorking() {
        self.stopUpdatingLocation()
        self.stopMonitoringSignificantLocationChanges()
    }
}
