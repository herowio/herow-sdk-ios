//
//  MockLocationManager.swift
//  herow_sdk_ios
//
//  Created by Damien on 16/02/2021.
//

import Foundation
import CoreLocation

class MockLocationManager: LocationManager {
    var monitoredRegions = Set<CLRegion>()
    var location: CLLocation?

    var heading: CLHeading?

    var delegate: CLLocationManagerDelegate?

    var pausesLocationUpdatesAutomatically: Bool = true

    var allowsBackgroundLocationUpdates: Bool = true

    var distanceFilter: CLLocationDistance = 50

    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyNearestTenMeters

    var activityType: CLActivityType = .otherNavigation

    var showsBackgroundLocationIndicator: Bool = false

    func requestAlwaysAuthorization() {

    }

    func accuracyAuthorizationStatus() -> CLAccuracyAuthorization {
        return .fullAccuracy
    }

    func authorizationStatus() -> CLAuthorizationStatus {
        return .authorizedWhenInUse
    }

    func authorizationStatusString() -> String {
        return "authorizedWhenInUse"
    }

    func accuracyAuthorizationStatusString() -> String {
        return "fullAccuracy"
    }

    func locationServicesEnabled() -> Bool {
        return true
    }

    func startMonitoring(region: CLRegion) {
        monitoredRegions.insert(region)
    }

    func stopMonitoring(region: CLRegion) {
        monitoredRegions.remove(region)
    }

    func getMonitoredRegions() -> Set<CLRegion> {
        return  monitoredRegions
    }

    func startMonitoringSignificantLocationChanges() {

    }

    func stopMonitoringSignificantLocationChanges() {

    }

    func startUpdatingLocation() {

    }

    func stopUpdatingLocation() {

    }

    func startMonitoringVisits() {

    }

    func stopMonitoringVisits() {

    }

    func registerClickAndCollectListener(listener: ClickAndConnectListener) {

    }

    func unregisterClickAndCollectListener(listener: ClickAndConnectListener) {

    }

    func registerDetectionListener(listener: DetectionEngineListener) {

    }

    func unregisterDetectionListener(listener: DetectionEngineListener) {

    }

    func updateClickAndCollectState() {

    }

    func setIsOnClickAndCollect(_ value: Bool) {

    }

    public func dispatchFakeLocation() {

    }

    


}
